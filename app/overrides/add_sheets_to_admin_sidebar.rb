Deface::Override.new(
  virtual_path: 'spree/layouts/admin',
  name: 'sheets_admin_sidebar_menu',
  insert_bottom: '#main-sidebar',
  text: '<% if can? :admin, Spree::Sheet %>
    <ul class="nav nav-sidebar">
      <%= tab Spree::Page, url: spree.admin_sheets_url, icon: "file", label: "Sheets" %>
    </ul>
  <% end %>'
)