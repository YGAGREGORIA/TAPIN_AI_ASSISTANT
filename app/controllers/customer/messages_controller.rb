class Customer::MessagesController < ApplicationController
  before_action :set_conversation

  SYSTEM_PROMPT = <<~PROMPT
  You are the TAPIN AI assistant.

  TAPIN is a fitness loyalty platform.
  Users earn points when they check into classes.

  You help users with:
  - check-ins
  - rewards
  - tier and points
  - class recommendations
  - deals
  - class schedules

  Answer clearly and briefly.
  PROMPT

  def create
    chat = current_user.chats.find(params[:conversation_id])
    user_text = params[:message].to_s.strip

    return render json: { error: "empty_message" }, status: :unprocessable_entity if user_text.blank?


    chat.messages.create!(
      role: "user",
      content: user_text
    )

    assistant_text = generate_ai_response(user_text)


    chat.messages.create!(
      role: "assistant",
      content: assistant_text
    )

    render json: { assistant: assistant_text }
  end

  private

  def generate_ai_response(user_text)
    text = user_text.downcase

    if text.include?("check-in")
      count = CheckIn.where(user: current_user).count
      "You have #{count} check-ins."

    elsif text.include?("reward")
      rewards = Reward.limit(3).pluck(:name)
      "You can unlock rewards like: #{rewards.join(", ")}."

    elsif text.include?("tier") || text.include?("points")
      points = current_user.points || 0
      tier = current_user.tier || "Bronze"
      "You are currently in the #{tier} tier with #{points} points."

    elsif text.include?("recommend") && text.include?("class")
      classes = Course.limit(3).pluck(:name)
      "Recommended classes: #{classes.join(", ")}."

    elsif text.include?("deal")
      deals = Deal.limit(3).pluck(:title)
      "Here are some deals: #{deals.join(", ")}."

    elsif text.include?("schedule")
      classes = Course.limit(3).pluck(:name)
      "Upcoming classes: #{classes.join(", ")}."

    else
      call_openai(user_text)
    end
  end

  def call_openai(user_text)
    client = OpenAI::Client.new

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: user_text }
        ]
      }
    )

    response.dig("choices", 0, "message", "content")
  end
end
