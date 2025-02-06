from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import speech_recognition as sr
import requests
import json
import os
from tempfile import NamedTemporaryFile
from eng import get_response_from_gemini, text_to_speech, ConversationContext, CONTEXT_DESCRIPTIONS
from langdetect import detect

app = Flask(__name__)
CORS(app)

@app.route('/get_contexts', methods=['GET'])
def get_contexts():
    return jsonify({
        'contexts': [
            {
                'id': context.value,
                'descriptions': CONTEXT_DESCRIPTIONS[context]
            } for context in ConversationContext
        ]
    })

@app.route('/process_audio', methods=['POST'])
def process_audio():
    try:
        audio_file = request.files.get('audio')
        context = request.form.get('context', 'casual')
        
        # Convert context string to enum
        try:
            conversation_context = ConversationContext(context)
        except ValueError:
            conversation_context = ConversationContext.CASUAL
            
        if not audio_file:
            return jsonify({'error': 'No audio file provided'}), 400

        # Save temporary audio file
        with NamedTemporaryFile(delete=False, suffix='.wav') as temp_audio:
            audio_file.save(temp_audio.name)
            
        # Convert audio to text
        recognizer = sr.Recognizer()
        with sr.AudioFile(temp_audio.name) as source:
            audio = recognizer.record(source)
        
        # Clean up temp file
        os.unlink(temp_audio.name)
        
        # Try to recognize in both Arabic and English
        text = None
        try:
            text = recognizer.recognize_google(audio, language="ar-SA")
        except:
            try:
                text = recognizer.recognize_google(audio, language="en-US")
            except sr.UnknownValueError:
                return jsonify({'error': 'Could not understand audio'}), 400
        
        if not text:
            return jsonify({'error': 'No speech detected'}), 400
            
        # Detect language and get AI response
        language = detect(text)
        ai_response = get_response_from_gemini(text, conversation_context)
        
        # Convert response to speech in appropriate language
        audio_file_path = text_to_speech(ai_response, language)
        
        if not audio_file_path:
            return jsonify({'error': 'Could not generate audio response'}), 500
            
        return jsonify({
            'user_text': text,
            'ai_response': ai_response,
            'language': language,
            'context': context,
            'audio_url': f'/get_audio/{os.path.basename(audio_file_path)}'
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/get_audio/<filename>', methods=['GET'])
def get_audio(filename):
    try:
        return send_file(filename, mimetype='audio/mpeg')
    except Exception as e:
        return jsonify({'error': str(e)}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000) 