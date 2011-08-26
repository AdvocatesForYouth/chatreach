class BrandsController < InheritedResources::Base
  before_filter :authenticate_user!
  before_filter :brand_admin, :only => [:update, :edit, :add_or_remove_admin]
  before_filter :admin, :only => [:create, :new, :destroy]  
  layout "application"
  
  def show
    session[:brand] = params[:id]
    flash[:success] = "Changed Brand"
    redirect_to :back
  end
  
  def update
    update! {edit_brand_path(@brand)}
  end
    
  private
    
  def brand_admin
    if !admin? 
      brand = Brand.find(params[:id])
      if !brand.admins.include?(current_user) 
        redirect_to :back
      end
    end
  end
end
