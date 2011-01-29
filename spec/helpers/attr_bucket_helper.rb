module AttrBucketHelper
  def a_class_with_bucket(opts)
    Item.delete_all
    Object.send :remove_const, :AttrBucketItem if Object.const_defined? :AttrBucketItem
    Object.const_set :AttrBucketItem, Class.new(Item) { attr_bucket opts }
  end

  def an_object_with_bucket(opts)
    a_class_with_bucket(opts).new
  end

  def persisted_item
    AttrBucketItem.first
  end
end