#!/bin/bash

# Create animations directory if it doesn't exist
mkdir -p assets/animations

# Download animations from LottieFiles
# Robot wave animation for empty state
curl -L "https://assets2.lottiefiles.com/packages/lf20_xyadoh9h.json" -o assets/animations/robot_wave.json

# Recycling animation for onboarding
curl -L "https://assets5.lottiefiles.com/packages/lf20_ydo1amjm.json" -o assets/animations/recycling.json

# Chat bot animation for onboarding
curl -L "https://assets9.lottiefiles.com/packages/lf20_xlmz9xwm.json" -o assets/animations/chat_bot.json

# Eco-friendly animation for onboarding
curl -L "https://assets3.lottiefiles.com/packages/lf20_ydo1amjm.json" -o assets/animations/eco_friendly.json

echo "Animations downloaded successfully!" 