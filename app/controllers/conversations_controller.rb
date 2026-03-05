class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:show]

  def index
    @chats = current_user.chats.order(created_at: :asc)
    @chat = @chats.last
    @messages = @chat&.messages&.order(created_at: :asc)
  end

  def show
    @chats = current_user.chats.order(created_at: :asc)
    @messages = @chat.messages.order(created_at: :asc)

    # reuse index UI
    render :index
  end

  def create
    studio = Studio.find_by(owner_email: current_user.email) || Studio.first

    if studio.nil?
      redirect_to root_path, alert: "Kein Studio gefunden."
      return
    end

    count = current_user.chats.count + 1

    chat = current_user.chats.create!(
      studio: studio,
      status: "active",
      title: "Chat #{count}"
    )

    redirect_to conversation_path(chat)
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end
end
