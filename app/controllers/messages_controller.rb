class MessagesController < ApplicationController
  before_action :authenticate_user!

  SYSTEM_PROMPT = <<~PROMPT
    You are the TAPIN AI assistant helping users with
    check-ins, rewards, loyalty tiers, classes and deals.
  PROMPT

  TITLE_PROMPT = <<~PROMPT
    Create a short chat title (max 6 words) that describes what the user wants.
    No quotes. No emojis. Title case is ok.
  PROMPT

  def create
    @chat = current_user.chats.find(params[:chat_id])

    user_text = params[:message].to_s.strip
    return render json: { error: "empty_message" }, status: :unprocessable_entity if user_text.blank?

    Message.create!(role: "user", content: user_text, chat: @chat)

    assistant_text = generate_ai_response(user_text)

    Message.create!(role: "assistant", content: assistant_text, chat: @chat)

    update_chat_title!

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
    llm = RubyLLM.chat(model: "gpt-4.1-mini")
    llm.with_instructions(SYSTEM_PROMPT)

    msgs = @chat.messages.order(:created_at).to_a

    # verhindert doppelt, weil user message schon gespeichert ist
    if msgs.last&.role == "user" && msgs.last.content.to_s.strip == user_text.to_s.strip
      msgs = msgs[0...-1]
    end

    msgs.each do |m|
      llm.add_message(role: m.role.to_sym, content: m.content)
    end

    response = llm.ask(user_text)
    response.content
  end

  def update_chat_title!
    # nur setzen, wenn titel noch default ist oder leer
    current = @chat.title.to_s.strip
    return if current.present? && !current.match?(/\AChat\s+\d+\z/i)

    messages = @chat.messages.order(:created_at).last(10)
    return if messages.empty?

    llm = RubyLLM.chat(model: "gpt-4.1-mini")
    llm.with_instructions(TITLE_PROMPT)

    messages.each do |m|
      llm.add_message(role: m.role.to_sym, content: m.content.to_s)
    end

    title = llm.ask("Generate the title now.").content.to_s.strip
    title = title.gsub(/\s+/, " ")
    title = title[0, 60]
    return if title.blank?

    @chat.update!(title: title)
  rescue => e
    Rails.logger.warn("chat title update failed: #{e.class}: #{e.message}")
    true
  end
end
