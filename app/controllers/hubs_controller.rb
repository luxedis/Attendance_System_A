class HubsController < ApplicationController
  before_action :set_hub, only: [:show, :edit, :update, :destroy]
  before_action :admin_user
  
  def index
    @hub = Hub.new
    @hubs = Hub.all.order('hub_number ASC')
  end

  def show
  end
  
  def new
    @hub = Hub.new
  end
  
  def create
    @hub = Hub.new(hub_params)
    if @hub.save
      flash[:success] = "拠点情報を作成しました。"
      redirect_to hubs_url
    else
      @hubs = Hub.all.order('hub_number ASC')
      redirect_to hubs_url
    end
  end
  
  def edit
  end
  
  def update
    if @hub.update_attributes(hub_params)
      flash[:success] = "拠点情報を更新しました。"
      redirect_to hubs_url
    else
      @hubs = Hub.all.order('hub_number ASC')
      redirect_to hubs_url
    end
  end
  
  def destroy
    @hub.destroy
    flash[:success] = "#{@hub.name}のデータを削除しました。"
    redirect_to hubs_url
  end
  
  
  private
  
  def set_hub
    @hub = Hub.find(params[:id])
  end
  
  def hub_params
    params.require(:hub).permit(:hub_number, :name, :attendance)
  end
end