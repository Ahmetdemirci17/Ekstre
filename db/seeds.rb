# Seed default categories with distinct matte banking colors
default_categories = [
  { name: "Market", color: "#2D936C" },       # Matte Sage
  { name: "Fatura", color: "#B91C1C" },       # Matte Crimson
  { name: "Ulaşım", color: "#D97706" },       # Matte Amber
  { name: "Eğlence", color: "#7C3AED" },      # Matte Violet
  { name: "Sağlık", color: "#BE185D" },       # Matte Rose
  { name: "Kira & Konut", color: "#2563EB" }, # Matte Blue
  { name: "Maaş / Gelir", color: "#059669" }, # Matte Forest
  { name: "Diğer", color: "#64748B" }         # Matte Slate Gray
]

default_categories.each do |cat|
  category = Category.find_or_initialize_by(name: cat[:name])
  category.color = cat[:color]
  category.save!
end

puts "Seeded #{Category.count} categories."
