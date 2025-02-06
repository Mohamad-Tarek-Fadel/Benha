import speech_recognition as sr
import requests
import json
import pyttsx3
import time
from pygame import mixer
import os
from langdetect import detect
from enum import Enum

# إعدادات API لـ Google Gemini
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent"
GEMINI_API_KEY = "AIzaSyB7BS5zZ-WHYj-KGDRvjvaz1uqU8JceEk0"  # مفتاح API الخاص بـ Google Gemini

# إعدادات API لـ Eleven Labs
ELEVENLABS_API_URL = "https://api.elevenlabs.io/v1/text-to-speech/generate"
ELEVENLABS_API_KEY = "sk_7e88349c2a03bbd1ab25237032a9a90a123bef7081b6c92a"  # مفتاح API الخاص بـ Eleven Labs

class ConversationContext(Enum):
    CASUAL = "casual"
    BUSINESS = "business"
    TRAVEL = "travel"
    ACADEMIC = "academic"

# Add context descriptions
CONTEXT_DESCRIPTIONS = {
    ConversationContext.CASUAL: {
        "en": "Everyday conversations with friends and family",
        "ar": "محادثات يومية مع الأصدقاء والعائلة"
    },
    ConversationContext.BUSINESS: {
        "en": "Professional workplace communication",
        "ar": "التواصل المهني في مكان العمل"
    },
    ConversationContext.TRAVEL: {
        "en": "Tourist situations and travel conversations",
        "ar": "مواقف السياحة ومحادثات السفر"
    },
    ConversationContext.ACADEMIC: {
        "en": "Educational and academic discussions",
        "ar": "المناقشات التعليمية والأكاديمية"
    }
}

def detect_language(text):
    try:
        return detect(text)
    except:
        return 'en'  # Default to English if detection fails

def recognize_audio(language=None):
    recognizer = sr.Recognizer()
    with sr.Microphone() as source:
        print("Listening... / جاري الاستماع...")
        recognizer.adjust_for_ambient_noise(source)
        audio = recognizer.listen(source)

    try:
        # If language is not specified, try to detect it from audio
        if not language:
            # Try Arabic first, then English if it fails
            try:
                text = recognizer.recognize_google(audio, language="ar-SA")
            except:
                text = recognizer.recognize_google(audio, language="en-US")
        else:
            text = recognizer.recognize_google(audio, language=language)
        return text
    except sr.UnknownValueError:
        return "Could not understand audio / لم أتمكن من فهم الصوت"
    except sr.RequestError as e:
        return f"Error with the speech recognition service / خطأ في خدمة التعرف على الصوت: {e}"

def get_response_from_gemini(text, context=ConversationContext.CASUAL):
    headers = {
        "Content-Type": "application/json",
    }
    params = {"key": GEMINI_API_KEY}
    
    lang = detect_language(text)
    
    # Add context-specific prompting
    context_prompt = f"""
    System: You are a bilingual AI language tutor fluent in Arabic and English.
    
    Current context: {context.value}
    Current user's language: {lang}
    User's message: {text}
    
    Rules for responding:
    1. If user speaks English: Respond with both English and Arabic, formatted as:
       English: [Your response]
       العربية: [Arabic translation]
       
    2. If user speaks Arabic: Respond in Arabic only
    
    3. Keep responses relevant to the current context ({context.value}):
       - For CASUAL: Use informal, friendly language
       - For BUSINESS: Use professional vocabulary and formal tone
       - For TRAVEL: Include relevant travel/tourism phrases
       - For ACADEMIC: Use academic terminology and formal language
    
    4. Include:
    - Context-appropriate vocabulary and phrases
    - Common expressions used in this context
    - Pronunciation tips for key terms
    - Brief cultural notes when relevant
    - Corrections for any context-inappropriate language
    
    5. Keep responses:
    - Focused on the selected context
    - Natural and encouraging
    - Brief but helpful (2-3 sentences per language)
    
    Respond now:
    """
    
    payload = {
        "contents": [{
            "parts": [{"text": context_prompt}],
            "role": "user"
        }],
        "generationConfig": {
            "temperature": 0.7,
            "topP": 0.8,
            "topK": 40,
            "maxOutputTokens": 800
        }
    }
    
    response = requests.post(GEMINI_API_URL, headers=headers, json=payload, params=params)
    
    if response.status_code == 200:
        try:
            response_text = response.json()["candidates"][0]["content"]["parts"][0]["text"]
            return response_text.strip()
        except KeyError:
            return "Could not process response / لم أتمكن من معالجة الرد"
    else:
        return "System error / خطأ في النظام"

def text_to_speech(text, language=None):
    if not language:
        language = detect_language(text)
    
    headers = {
        "Accept": "audio/mpeg",
        "Content-Type": "application/json",
        "xi-api-key": ELEVENLABS_API_KEY
    }

    # Select appropriate voice ID based on language
    voice_id = "21m00Tcm4TlvDq8ikWAM"  # Default English voice
    if language == 'ar':
        voice_id = "arabic_voice_id"  # Replace with actual Arabic voice ID

    payload = {
        "text": text,
        "model_id": "eleven_multilingual_v1",
        "voice_id": voice_id
    }
    
    response = requests.post(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}/stream", 
        headers=headers, 
        json=payload
    )

    if response.status_code == 200:
        audio_file = f"response_{int(time.time())}.mp3"
        with open(audio_file, "wb") as f:
            f.write(response.content)
        return audio_file
    else:
        print(f"TTS Error: {response.status_code}, {response.text}")
        return None

def play_audio(file_path):
    try:
        mixer.init()
        mixer.music.load(file_path)
        mixer.music.play()
        # Wait for the audio to finish playing
        while mixer.music.get_busy():
            time.sleep(0.1)
        mixer.music.unload()
        mixer.quit()
    except Exception as e:
        print(f"Error playing audio: {e}")

def main():
    print("📞 النظام جاهز للمحادثة!")
    print("قل 'إيقاف' للخروج من البرنامج")
    
    while True:
        try:
            # 1. Listen for user input
            text = recognize_audio()
            if not text or text == "لم أتمكن من فهم الصوت":
                continue
                
            print(f"🎤 أنت: {text}")

            if text.lower() == "إيقاف":
                print("🛑 إيقاف النظام.")
                break
            
            # 2. Get Gemini response
            gemini_response = get_response_from_gemini(text)
            print(f"🤖 المساعد: {gemini_response}")

            # 3. Convert to speech and play immediately
            audio_file = text_to_speech(gemini_response)
            if audio_file:
                play_audio(audio_file)
                # Clean up the audio file after playing
                try:
                    os.remove(audio_file)
                except:
                    pass
            
        except KeyboardInterrupt:
            print("\n🛑 تم إيقاف البرنامج.")
            break
        except Exception as e:
            print(f"حدث خطأ: {e}")
            continue

if __name__ == "__main__":
    main()
