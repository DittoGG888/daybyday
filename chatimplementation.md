# Chat Implementation Plan

## Goal
Create a supportive AI chatbot for DayByDay that feels like a calm personal coach rather than a general-purpose chatbot.

## Core Direction
The chatbot should help users reflect on their mood, habits, goals, and daily life in a short, encouraging, and practical way.

## Recommended Approach

### Option 1: Fastest path
Use Google Gemini through a small backend endpoint in Firebase Functions.

Benefits:
- Quick to implement
- Easy to connect from Flutter
- Good for prototyping and testing

### Option 2: Most free and privacy-friendly
Use Ollama with a small local model such as Llama 3.2 3B, Phi-3, or Gemma.

Benefits:
- No API cost
- More private
- Better for long-term experimentation

For a first version, Gemini is the fastest path. For a truly free setup, Ollama is the better long-term choice.

## How the chatbot should behave
The bot should:
- be warm and empathetic
- keep responses short
- offer one small insight or action
- encourage reflection and consistency
- avoid diagnosis or medical advice
- encourage professional help if the user seems in crisis

## What context the bot should use
The chatbot should use available user data to make replies feel personal, including:
- latest mood check-in
- recent journal entries
- current goals
- sleep, screen time, and activity patterns
- assessment results

## Suggested architecture
- Flutter chat screen in the app
- Firestore for storing chat history and user context
- Firebase Functions as the backend layer
- A system prompt that defines the bot as DayByDay Coach

## Initial system prompt
You are DayByDay Coach, a calm and supportive personal growth assistant.
Your job is to help the user reflect on their mood, habits, goals, and daily life.
Be warm, concise, and encouraging.
Do not diagnose or give medical advice.
If the user seems in crisis, encourage them to contact a trusted professional or emergency help.
Use the user context provided to make your reply feel personal.
Keep responses short and practical.

## Implementation steps
1. Build a basic chat UI in Flutter.
2. Save chat messages in Firestore.
3. Create a backend endpoint in Firebase Functions.
4. Send the latest message, chat history, and user context to the AI model.
5. Return the AI response to the app.
6. Add simple safety rules and rate limiting.

## Recommendation
Start with a simple Gemini-based version first, then expand with richer personalization once the core chat experience works well.
