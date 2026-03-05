class MessagesController < ApplicationController
  before_action :authenticate_user!

  SYSTEM_PROMPT = <<~PROMPT
    You are the TAPIN AI assistant helping users with
    check-ins, rewards, loyalty tiers, classes and deals.
  PROMPT

  def create
    @chat = current_user.chats.find(params[:conversation_id])

    user_text = params[:message]

    # save user message
    Message.create!(role: "user", content: user_text, chat: @chat)

    # generate response
    assistant_text = generate_ai_response(user_text)

    # save assistant message
    Message.create!(role: "assistant", content: assistant_text, chat: @chat)

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
      "You can unlock rewards like: #{rewards.join(', ')}."

    elsif text.include?("recommend") && text.include?("class")
      classes = Course.limit(3).pluck(:name)
      "Recommended classes: #{classes.join(', ')}."

    elsif text.include?("deal")
      deals = Deal.limit(3).pluck(:title)
      "Here are some deals: #{deals.join(', ')}."

    elsif text.include?("schedule")
      classes = Course.limit(3).pluck(:name)
      "Upcoming classes: #{classes.join(', ')}."

    else
      call_openai(user_text)
    end
  end

  def call_openai(user_text)
    ruby_llm_chat = RubyLLM.chat(model: "gpt-4o-mini")

    response = ruby_llm_chat
               .with_instructions(SYSTEM_PROMPT)
               .ask(user_text)

    response.content
  end
end
