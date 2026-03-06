class MessagesController < ApplicationController
  before_action :authenticate_user!

  PROMPT_DIR = Rails.root.join("app", "prompts")
  CUSTOMER_SYSTEM_PROMPT = PROMPT_DIR.join("customer_system_prompt.txt").read.freeze
  ADMIN_SYSTEM_PROMPT = PROMPT_DIR.join("admin_system_prompt.txt").read.freeze

  def create
    @chat = current_user.chats.find(params[:chat_id])

    user_text = params[:message].to_s.strip
    uploaded_file = params[:file]

    if user_text.blank? && uploaded_file.blank?
      return render json: { error: "empty_message" },
                    status: :unprocessable_entity
    end

    # save user message
    user_message = Message.new(
      role: "user",
      content: user_text.presence || uploaded_file&.original_filename.to_s,
      chat: @chat
    )

    user_message.file.attach(uploaded_file) if uploaded_file.present? && user_message.respond_to?(:file)
    user_message.save!

    # generate response — file upload, admin, or customer AI
    assistant_text = if uploaded_file.present?
                       process_file(uploaded_file)
                     elsif current_user.admin?
                       generate_admin_response(user_text)
                     else
                       generate_customer_response(user_text)
                     end

    # save assistant message
    Message.create!(role: "assistant", content: assistant_text, chat: @chat)

    # Auto-rename chat based on first user message
    new_title = maybe_rename_chat(user_text.presence || uploaded_file&.original_filename.to_s)

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

  # --- Customer flow (all messages go through AI) ---

  def generate_customer_response(_user_text)
    call_openai(build_customer_prompt)
  end

  # --- File upload processing ---

  def process_file(file)
    if file.content_type == "application/pdf"
      chat = RubyLLM.chat(model: "gpt-4o")
      response = chat.ask("Please analyze this PDF and tell me what it contains.", with: file.tempfile.path)
      response.content
    elsif file.content_type.start_with?("image/")
      chat = RubyLLM.chat(model: "gpt-4o")
      response = chat.ask("Describe exactly what you see in this image. If there is text in the image, read it too.",
                          with: file.tempfile.path)
      response.content
    elsif file.content_type.start_with?("audio/")
      chat = RubyLLM.chat(model: "gpt-4o-audio-preview")
      response = chat.ask("Please transcribe and summarize this audio.", with: file.tempfile.path)
      response.content
    else
      "Unsupported file type."
    end
  rescue StandardError => e
    Rails.logger.error("File processing error: #{e.class} - #{e.message}")
    "Sorry, I had trouble processing that file."
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

    system_prompt = "#{ADMIN_SYSTEM_PROMPT}\n\nHere is the real data from the studio:\n\n#{context_parts.join("\n\n")}"

    call_openai(system_prompt)
  rescue StandardError => e
    Rails.logger.error("Admin AI error: #{e.message}")
    "Sorry, I had trouble fetching studio data. Please try again."
  end

  def build_customer_prompt
    studio = @chat.studio
    prompt = CUSTOMER_SYSTEM_PROMPT.dup

    # Studio info
    prompt << "\n\n--- STUDIO INFORMATION ---\n"
    prompt << "Name: #{studio.name}\n"
    prompt << "Address: #{studio.address}\n" if studio.address.present?
    prompt << "Phone: #{studio.phone}\n" if studio.phone.present?
    prompt << "Email: #{studio.email}\n" if studio.email.present?
    prompt << "Opening Hours: #{studio.opening_hours}\n" if studio.opening_hours.present?
    prompt << "Facilities: #{studio.facilities}\n" if studio.facilities.present?
    prompt << "Pricing: #{studio.pricing}\n" if studio.pricing.present?

    # Courses
    courses = Course.where(studio: studio)
    if courses.any?
      prompt << "\n--- CLASSES ---\n"
      courses.each do |c|
        prompt << "\n#{c.name} (#{c.category})\n"
        prompt << "  Schedule: #{c.schedule}\n" if c.schedule.present?
        prompt << "  Duration: #{c.duration} minutes\n" if c.duration.present?
        prompt << "  Difficulty: #{c.difficulty}\n" if c.difficulty.present?
        prompt << "  Description: #{c.description}\n" if c.description.present?
        prompt << "  Benefits: #{c.benefits}\n" if c.benefits.present?
        prompt << "  What to bring: #{c.what_to_bring}\n" if c.what_to_bring.present?
        prompt << "  What to wear: #{c.what_to_wear}\n" if c.what_to_wear.present?
        prompt << "  Recovery tips: #{c.recovery_tips}\n" if c.recovery_tips.present?
        prompt << "  Best for: #{c.best_for}\n" if c.best_for.present?
      end
    end

    # Active deals
    deals = Deal.where(studio: studio, active: true)
    if deals.any?
      prompt << "\n--- CURRENT DEALS ---\n"
      deals.each do |d|
        prompt << "#{d.title}: #{d.description}\n"
      end
    end

    # Rewards
    rewards = Reward.where(studio: studio)
    if rewards.any?
      prompt << "\n--- REWARDS PROGRAM ---\n"
      rewards.each do |r|
        prompt << "#{r.name} (#{r.reward_type}): #{r.required_checkins} check-ins required\n"
      end
    end

    # Member-specific context
    checkin_count = CheckIn.where(user: current_user).count
    tier = case checkin_count
           when 0..9 then "Member"
           when 10..24 then "Bronze"
           when 25..49 then "Silver"
           else "Gold"
           end
    next_tier = case tier
                when "Member" then "#{10 - checkin_count} more check-ins to reach Bronze"
                when "Bronze" then "#{25 - checkin_count} more check-ins to reach Silver"
                when "Silver" then "#{50 - checkin_count} more check-ins to reach Gold"
                else "They've reached the highest tier!"
                end

    prompt << "\n--- THIS MEMBER'S INFO ---\n"
    prompt << "Name: #{current_user.first_name} #{current_user.last_name}\n"
    prompt << "Check-ins: #{checkin_count}\n"
    prompt << "Tier: #{tier} (#{next_tier})\n"

    user_rewards = current_user.user_rewards.includes(:reward)
    if user_rewards.any?
      prompt << "Reward progress:\n"
      user_rewards.each do |ur|
        status = ur.redeemed? ? "Unlocked" : "#{ur.progress}/#{ur.reward.required_checkins}"
        prompt << "  #{ur.reward.name}: #{status}\n"
      end
    end

    prompt
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
  rescue StandardError => e
    Rails.logger.error("OpenAI error: #{e.class} - #{e.message}")
    "I'm not sure how to help with that yet. Try asking about your check-ins, rewards, classes, or deals!"
  end
end
