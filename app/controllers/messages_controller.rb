class MessagesController < ApplicationController
  before_action :authenticate_user!

  CUSTOMER_SYSTEM_PROMPT = <<~PROMPT
    You are the TAPIN AI assistant helping users with
    check-ins, rewards, loyalty tiers, classes and deals.
  PROMPT

  ADMIN_SYSTEM_PROMPT = <<~PROMPT
    You are TapIn AI, a helpful assistant for fitness studio administrators.
    You help studio owners understand their members, track engagement, and improve retention.
    Be concise, friendly, and actionable in your responses.
    Always base your answers on the data provided — never make up numbers.
  PROMPT

  def create
    @chat = current_user.chats.find(params[:chat_id])

    user_text = params[:message].to_s.strip
    return render json: { error: "empty_message" }, status: :unprocessable_entity if user_text.blank?

    # save user message
    Message.create!(role: "user", content: user_text, chat: @chat)

    # generate response — admin gets tool-augmented AI, customer gets keyword + AI
    assistant_text = if current_user.admin?
                       generate_admin_response(user_text)
                     else
                       generate_customer_response(user_text)
                     end

    # save assistant message
    Message.create!(role: "assistant", content: assistant_text, chat: @chat)

    render json: { assistant: assistant_text }
  end

  private

  # --- Customer flow (keyword matching + RubyLLM fallback) ---

  def generate_customer_response(user_text)
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
      call_openai(CUSTOMER_SYSTEM_PROMPT)
    end
  end

  # --- Admin flow (detect tool need, fetch data, send to AI) ---

  def generate_admin_response(user_text)
    studio = @chat.studio
    text = user_text.downcase

    # Gather relevant tool data based on the question
    context_parts = []

    if text.match?(/inactive|haven.t (come|been|checked|visited)|absent|missing/)
      data = AdminTools::Registry.call("get_inactive_members", studio: studio)
      context_parts << "INACTIVE MEMBERS DATA:\n#{data.to_json}"
    end

    if text.match?(/churn|risk|leav|cancel|drop|losing/)
      data = AdminTools::Registry.call("analyze_churn_risk", studio: studio)
      context_parts << "CHURN RISK DATA:\n#{data.to_json}"
    end

    if text.match?(/member|insight|detail|progress|close to reward/)
      data = AdminTools::Registry.call("get_member_insights", studio: studio)
      context_parts << "MEMBER INSIGHTS DATA:\n#{data.to_json}"
    end

    if text.match?(/deal|promot|offer|discount|campaign/)
      data = AdminTools::Registry.call("suggest_deal", studio: studio)
      context_parts << "DEAL SUGGESTIONS DATA:\n#{data.to_json}"
    end

    if text.match?(/loyalty|retention|reward|program|improv/)
      data = AdminTools::Registry.call("advise_loyalty_program", studio: studio)
      context_parts << "LOYALTY PROGRAM DATA:\n#{data.to_json}"
    end

    # If no specific tool matched, provide a general overview
    if context_parts.empty?
      data = AdminTools::Registry.call("advise_loyalty_program", studio: studio)
      context_parts << "STUDIO OVERVIEW DATA:\n#{data.to_json}"
    end

    system_prompt = ADMIN_SYSTEM_PROMPT + "\n\nHere is the real data from the studio:\n\n" + context_parts.join("\n\n")

    call_openai(system_prompt)
  rescue => e
    Rails.logger.error("Admin AI error: #{e.message}")
    "Sorry, I had trouble fetching studio data. Please try again."
  end

  def call_openai(system_prompt)
    ruby_llm_chat = RubyLLM.chat(model: "gpt-4.1-mini")

    history = @chat.messages.order(:created_at).map do |m|
      { role: m.role, content: m.content }
    end

    response = ruby_llm_chat
               .with_instructions(system_prompt)
               .ask(history)

    response.content
  end
end
