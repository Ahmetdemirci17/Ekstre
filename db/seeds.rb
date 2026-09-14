# Seed default categories with distinct colors
default_categories = [
  { name: "Market", color: "#10B981" },       # Emerald
  { name: "Fatura", color: "#EF4444" },       # Red
  { name: "Ulaşım", color: "#F59E0B" },       # Amber
  { name: "Eğlence", color: "#8B5CF6" },      # Purple
  { name: "Sağlık", color: "#EC4899" },       # Pink
  { name: "Kira & Konut", color: "#3B82F6" }, # Blue
  { name: "Maaş / Gelir", color: "#059669" }, # Dark Green
  { name: "Diğer", color: "#6B7280" }         # Gray
]

default_categories.each do |cat|
  Category.find_or_create_by!(name: cat[:name]) do |c|
    c.color = cat[:color]
  end
end

puts "Seeded #{Category.count} categories."
