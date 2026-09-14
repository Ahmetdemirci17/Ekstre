# Bank Statement Budget Tracker - System Design & Architecture

## Overview
A Rails 8 web application for importing bank statement files (CSV), auto-categorizing transactions using the Gemini API, providing manual category overrides via Hotwire (Turbo Frames), and visualizing monthly spending trends with Chart.js dashboards.

---

## Architecture & Tech Stack
- **Framework**: Ruby 4.0.6, Ruby on Rails 8.1.3
- **Database**: PostgreSQL (Development & Production)
- **Frontend / Interactivity**: Hotwire (Turbo Drive, Turbo Frames, Turbo Streams) + Stimulus JS
- **Styling**: Tailwind CSS (via `tailwindcss-rails`)
- **Visualizations**: Chart.js loaded via CDN and encapsulated within an isolated Stimulus controller
- **Background Jobs**: ActiveJob backed by Solid Queue
- **AI Categorization**: `GeminiCategorizer` service using `HTTParty` / REST API to Gemini (`gemini-2.5-flash` or configurable model), reading API key from credentials / `ENV["GEMINI_API_KEY"]`
- **File Parsing**: `CSV` stdlib with flexible Turkish bank format detection; structured for future PDF extension (`pdf-reader`)

---

## Data Models & Database Schema

### 1. `Category`
Represents spending classification tags.
- `name` (string, null: false, unique index)
- `color` (string, default: "#6B7280")
- Associations: `has_many :transactions`

### 2. `Statement`
Represents an uploaded bank statement file.
- `source_filename` (string, null: false)
- `imported_at` (datetime, null: false, default: -> { 'CURRENT_TIMESTAMP' })
- `bank_name` (string, nullable)
- `status` (string, default: "uploaded", enum: uploaded, parsed, categorized, failed)
- Associations: `has_many :transactions, dependent: :destroy`

### 3. `Transaction`
Represents an individual bank transaction / line item.
- `statement_id` (bigint, foreign_key, null: false)
- `category_id` (bigint, foreign_key, nullable)
- `date` (date, null: false)
- `description` (text, null: false)
- `amount` (decimal(12, 2), null: false)
- `raw_row` (text, nullable)
- `categorized_by` (integer, default: 0, enum: { unassigned: 0, manual: 1, ai: 2 })
- Associations:
  - `belongs_to :statement`
  - `belongs_to :category, optional: true`
