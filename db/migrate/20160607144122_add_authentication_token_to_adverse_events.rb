class AddAuthenticationTokenToAdverseEvents < ActiveRecord::Migration
  def change
    add_column :adverse_events, :authentication_token, :string
    add_index  :adverse_events, :authentication_token, unique: true
  end
end
