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

    # Auto-rename chat based on first user message
    new_title = maybe_rename_chat(user_text)

    render json: { assistant: assistant_text, title: new_title }
  end

  private

  # Rename chat to a short summary of the first user message
  def maybe_rename_chat(user_text)
    return nil unless @chat.title&.match?(/\AChat \d+\z/)

    title = user_text.truncate(40, omission: "...")
    @chat.update!(title: title)
    title
  end

  # --- Customer flow (keyword matching + RubyLLM fallback) ---

  def generate_customer_response(user_text)
    text = user_text.downcase

    if text.match?(/check.?in|visit|attendance|how many/)
      count = CheckIn.where(user: current_user).count
      studio = current_user.studio
      tier = case count
             when 0..9 then "Member"
             when 10..24 then "Bronze"
             when 25..49 then "Silver"
             else "Gold"
             end
      "You have #{count} check-ins! Your current tier is #{tier}."

    elsif text.match?(/reward|unlock|earn|points|badge/)
      user_rewards = current_user.user_rewards.includes(:reward)
      if user_rewards.any?
        lines = user_rewards.map do |ur|
          status = ur.redeemed? ? "Unlocked" : "#{ur.progress}/#{ur.reward.required_checkins}"
          "#{ur.reward.name}: #{status}"
        end
        "Your rewards:\n#{lines.join("\n")}"
      else
        rewards = Reward.limit(3).pluck(:name)
        "You can unlock rewards like: #{rewards.join(', ')}."
      end

    elsif text.match?(/class|recommend|workout|exercise|train/)
      classes = Course.limit(5).pluck(:name, :category)
      lines = classes.map { |name, cat| "#{name} (#{cat})" }
      "Here are some classes you might enjoy:\n#{lines.join("\n")}"

    elsif text.match?(/deal|offer|discount|promo|special/)
      deals = Deal.where(active: true).pluck(:title, :description)
      if deals.any?
        lines = deals.map { |title, desc| "#{title} — #{desc}" }
        "Active deals:\n#{lines.join("\n")}"
      else
        "No active deals right now, but check back soon!"
      end

    elsif text.match?(/schedule|upcoming|when|time/)
      classes = Course.limit(5).pluck(:name)
      "Upcoming classes: #{classes.join(', ')}."

    elsif text.match?(/tier|level|status|rank/)
      count = CheckIn.where(user: current_user).count
      tier = case count
             when 0..9 then "Member"
             when 10..24 then "Bronze"
             when 25..49 then "Silver"
             else "Gold"
             end
      next_tier = case tier
                  when "Member" then "#{10 - count} more check-ins to reach Bronze"
                  when "Bronze" then "#{25 - count} more check-ins to reach Silver"
                  when "Silver" then "#{50 - count} more check-ins to reach Gold"
                  else "You've reached the highest tier!"
                  end
      "You're currently at #{tier} tier with #{count} check-ins. #{next_tier}"

    elsif text.match?(/hi|hello|hey|help|what can you/)
      "Hey#{current_user.first_name.present? ? " #{current_user.first_name}" : ""}! I can help you with:\n" \
      "- Your check-ins and tier status\n" \
      "- Available rewards and progress\n" \
      "- Class recommendations\n" \
      "- Current deals and offers\n" \
      "Just ask me anything!"

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
  rescue => e
    Rails.logger.error("OpenAI error: #{e.class} - #{e.message}")
    "I'm not sure how to help with that yet. Try asking about your check-ins, rewards, classes, or deals!"
  end
end
