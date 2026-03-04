class ChatAiService
  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are TapIn AI, a helpful assistant for fitness studio administrators.
    You help studio owners understand their members, track engagement, and improve retention.

    When the admin asks about members, churn, rewards, deals, or loyalty programs,
    use the available tools to fetch real data before responding.
    Always base your answers on actual data from the tools — never make up numbers.

    Be concise, friendly, and actionable in your responses.
  PROMPT

  OPENAI_TOOLS = [
    {
      type: "function",
      function: {
        name: "get_inactive_members",
        description: "Get a list of studio members who haven't checked in recently",
        parameters: {
          type: "object",
          properties: {
            days_threshold: { type: "integer", description: "Number of days of inactivity (default: 30)" }
          },
          required: []
        }
      }
    },
    {
      type: "function",
      function: {
        name: "analyze_churn_risk",
        description: "Analyze which members are at risk of leaving the studio",
        parameters: { type: "object", properties: {}, required: [] }
      }
    },
    {
      type: "function",
      function: {
        name: "get_member_insights",
        description: "Get detailed insights about a specific member, or find members close to earning rewards",
        parameters: {
          type: "object",
          properties: {
            user_id: { type: "integer", description: "Specific member ID (optional — omit to see members close to rewards)" }
          },
          required: []
        }
      }
    },
    {
      type: "function",
      function: {
        name: "suggest_deal",
        description: "Get AI-suggested deals based on current member data and engagement patterns",
        parameters: { type: "object", properties: {}, required: [] }
      }
    },
    {
      type: "function",
      function: {
        name: "advise_loyalty_program",
        description: "Get advice on how to improve the studio's loyalty program based on current metrics",
        parameters: { type: "object", properties: {}, required: [] }
      }
    }
  ].freeze

  MAX_TOOL_ROUNDS = 3

  def initialize(chat:)
    @chat = chat
    @studio = chat.studio
    @client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
  end

  def reply
    messages = build_messages

    MAX_TOOL_ROUNDS.times do
      response = @client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: messages,
          tools: OPENAI_TOOLS,
          tool_choice: "auto"
        }
      )

      choice = response.dig("choices", 0, "message")

      # If the model wants to call tools, execute them and loop
      if choice["tool_calls"].present?
        messages << choice

        choice["tool_calls"].each do |tool_call|
          tool_name = tool_call.dig("function", "name")
          tool_args = JSON.parse(tool_call.dig("function", "arguments") || "{}")
          tool_result = call_admin_tool(tool_name, **tool_args.symbolize_keys)

          messages << {
            role: "tool",
            tool_call_id: tool_call["id"],
            content: tool_result.to_json
          }
        end
      else
        # Final text response
        return choice["content"]
      end
    end

    # Fallback if we hit the tool round limit
    "I gathered the data but couldn't complete the response. Please try again."
  rescue Faraday::Error, OpenAI::Error => e
    Rails.logger.error("ChatAiService error: #{e.message}")
    "Sorry, I'm having trouble connecting to the AI service right now. Please try again later."
  end

  private

  def build_messages
    messages = [{ role: "system", content: SYSTEM_PROMPT }]

    @chat.messages.order(:created_at).each do |msg|
      messages << { role: msg.role, content: msg.content }
    end

    messages
  end

  def call_admin_tool(tool_name, **params)
    AdminTools::Registry.call(tool_name, studio: @studio, **params)
  rescue ArgumentError => e
    { error: e.message }
  end
end
