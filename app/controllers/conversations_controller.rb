class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:show, :reply]

  def index
    @chats = current_user.chats.order(created_at: :asc)
  end

  def show
    @chats = current_user.chats.order(created_at: :asc)
    @messages = @chat.messages.order(created_at: :asc)
  end

  def create
    studio = Studio.find_by(owner_email: current_user.email) || Studio.first

    chat = current_user.chats.create!(
      studio: studio,
      status: "active"
    )

    redirect_to conversation_path(chat.id)
  end

  def reply
    user_text = params[:message].to_s.strip
    return render json: { error: "empty_message" }, status: :unprocessable_entity if user_text.blank?

    @chat.messages.create!(role: "user", content: user_text)

    assistant_text = "Got it. You said: #{user_text}"
    @chat.messages.create!(role: "assistant", content: assistant_text)

    render json: { assistant: assistant_text }
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end
end
