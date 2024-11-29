admin = User.create!(
    email: 'admin@example.com',
    password: 'password123',
    role: 'admin'
)

puts "Admin created with email: #{admin.email} and password: #{admin.password}"