class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:show]

  def index
    @chats = current_user.chats.includes(:messages).order(created_at: :desc)  end

  def show
    @chats = current_user.chats.order(created_at: :asc)
    @messages = @chat.messages.order(created_at: :asc)
  end

  def create
    studio = current_user.studios.first

    unless studio
      redirect_to root_path, alert: "No studio found"
      return
    end

    chat = current_user.chats.create!(
      studio: studio,
      status: "active",
      title: "Chat #{current_user.chats.count + 1}"
    )

    redirect_to chat_path(chat)
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end
end
