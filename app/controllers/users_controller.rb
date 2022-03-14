class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy image preview_image images start play input finished]

  # GET /users or /users.json
  def index
    @users = User.all
  end

  # GET /users/1 or /users/1.json
  def show
    case @user.state
    when User::STATE_IDLE
    when User::STATE_STARTED
      redirect_to play_user_path(@user)
    when User::STATE_FINISHED
      redirect_to finished_user_path(@user)
    end
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to user_url(@user), notice: "User was successfully created." }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to user_url(@user), notice: "User was successfully updated." }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url, notice: "User was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def image
    step = params[:step] || @user.step
    step = step.to_i
    img = @user.image(step)
    send_data(img.data, filename: "image_#{@user.id}_#{step}.jpg", disposition: 'attachment')
  end

  def preview_image
    send_data(@user.image.data, filename: 'image.jpg', disposition: 'attachment')
  end

  def images
  end

  def start
    @user.start
    redirect_to play_user_path(@user)
  end

  def play
  end

  def input
    @user.input params['number'].to_i
    puts "*"* 80, params['numbrer'].to_i
    if @user.finished?
      redirect_to finished_user_path(@user)
    else 
      redirect_to play_user_path(@user)
    end
  end

  def finished
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:user_id, :state)
    end
end
