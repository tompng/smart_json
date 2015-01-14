# smart_json
includesしなくてもN+1をちゃんとしてくれるas_jsonぽい奴

sample
```ruby
class Post < ActiveRecord::Base
  smart_json(:simple){{title: title}}
end
class User < ActiveRecord::Base
  smart_json(:only_name){{name: name}}
  smart_json(:with_image){{profile: {image: profile.image}}}.require(:profile)
end
class Comment < ActiveRecord::Base
  smart_json(:default){{content: content}}
end

Blog.all.as_smart_json(
  owner: :with_image,
  posts: [
    :simple,
    author: :only_name,
    comments: [
      user: [:only_name, :with_image],
    ]
  ]
)
```

bad sample without smart_json
```ruby
Blog.all.includes(
  owner: :profile,
  posts: [
    :author,
    comments: {user: :profile}
  ]
).as_json(
  include: {
    owner: {only: [], include: {profile: {only: :image}}},
    posts: {
      only: :title,
      include: {
        author: {only: :name},
        comments: {
          only: :content,
          include: {
            user: {only: :name, include: {profile: {only: :image}}},
          }
        }
      }
    }
  }
)
```
