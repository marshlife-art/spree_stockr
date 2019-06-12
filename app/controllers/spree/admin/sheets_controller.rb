module Spree
  module Admin
    class SheetsController < Spree::Admin::ResourceController
      def index
        @sheets = Spree::Sheet.page params[:page]
      end

      def create
        sheet = Spree::Sheet.create!(sheet_params)
        redirect_to admin_sheets_url
      end

      def edit
        @sheet = Spree::Sheet.find_by_id(params[:id])
      end
     
      private
      def sheet_params
        params.require(:spree_sheet).permit(:file, :name, :header_row)
      end

    end
  end
end
