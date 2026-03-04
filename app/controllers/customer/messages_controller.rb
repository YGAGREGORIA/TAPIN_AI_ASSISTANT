class Customer::MessagesController < ApplicationController
  before_action :set_conversation

  def create
    user_message = params[:content]

    # Save user message
    @conversation.messages.create!(
      role: "user",
      content: user_message
    )

    ai_response = process_message(user_message)

    # Save AI response
    @conversation.messages.create!(
      role: "assistant",
      content: ai_response
    )

    redirect_to conversation_path(@conversation)
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def process_message(message)
    message = message.downcase

    if message.include?("check-in") || message.include?("check in")
      count = CheckIn.where(user: current_user).count
      "You have #{count} check-ins."

    elsif message.include?("reward")
      rewards = Reward.limit(3).pluck(:name)
      "You can unlock rewards such as: #{rewards.join(", ")}."

    elsif message.include?("tier") || message.include?("points")
      points = current_user.points || 0
      tier = current_user.tier || "Bronze"
      "You are currently in the #{tier} tier with #{points} points."

    elsif message.include?("class") && message.include?("recommend")
      classes = Course.limit(3).pluck(:name)
      "Recommended classes: #{classes.join(", ")}."

    elsif message.include?("deal")
      deals = Deal.limit(3).pluck(:title)
      "Here are some deals: #{deals.join(", ")}."

    elsif message.include?("schedule")
      classes = Course.limit(3).pluck(:name)
      "Upcoming classes: #{classes.join(", ")}."

    else
      "I can help you with check-ins, rewards, points, classes, deals, or schedules."
    end
  end
end
