class RemoveStatusFromSubjects < ActiveRecord::Migration
  def up
    remove_index :subjects, :status
    remove_column :subjects, :status
  end

  def down
    add_column :subjects, :status, :string, null: false, default: 'valid'
    add_index :subjects, :status
  end
end
