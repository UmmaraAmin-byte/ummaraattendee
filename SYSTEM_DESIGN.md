# Event & Venue Management System Design

## 1) Architecture

### Logical Components

- Client apps (Web/Mobile)
- API Gateway
- Auth Service (JWT + RBAC)
- Venue Service (buildings, rooms, availability)
- Event Service (draft/publish/templates)
- Booking Service (conflict-safe reservations)
- Notification Service (email/in-app)
- Analytics Service (aggregations, dashboards)
- PostgreSQL (primary OLTP store)
- Redis (cache + distributed locks + queue)

### Core Flow

1. Organizer creates event (draft/published).
2. Organizer searches available rooms by date, capacity, location, amenities.
3. Booking service validates:
   - room capacity
   - availability slot coverage
   - no overlap with existing non-cancelled bookings
4. Booking created transactionally, event linked to booking.
5. Real-time update (ws/polling) updates availability in UI.

### Scalability Notes

- Horizontal API scale behind load balancer
- Redis lock for room/time booking to prevent race conditions
- DB transaction with unique overlap constraints/index strategy
- Read-heavy list/search endpoints cached
- Async notifications/events via queue

## 2) Database Schema (PostgreSQL)

### users
- id (pk, uuid)
- full_name
- email (unique)
- password_hash
- role enum: venue_owner, organizer, super_admin
- created_at, updated_at

### buildings
- id (pk)
- owner_id (fk users.id)
- name, address, description
- image_url
- created_at, updated_at

### rooms
- id (pk)
- building_id (fk buildings.id)
- name
- capacity (int)
- pricing (numeric nullable)
- amenities (jsonb/text[])
- created_at, updated_at

### availability_slots
- id (pk)
- room_id (fk rooms.id)
- start_at (timestamptz)
- end_at (timestamptz)
- is_blocked (bool)
- recurrence_rule (nullable)
- created_at, updated_at

### events
- id (pk)
- organizer_id (fk users.id)
- title, description
- category (nullable)
- expected_attendees (int)
- start_at, end_at (timestamptz)
- status enum: draft, published, cancelled, completed
- template_source_id (fk events.id nullable)
- created_at, updated_at

### bookings
- id (pk)
- event_id (fk events.id unique)
- room_id (fk rooms.id)
- start_at, end_at (timestamptz)
- status enum: pending, confirmed, cancelled
- created_at, updated_at

## 3) API Endpoints (REST)

### Auth
- POST `/api/auth/register`
- POST `/api/auth/login`
- POST `/api/auth/logout`

### Venue Owner
- GET `/api/owner/buildings`
- POST `/api/owner/buildings`
- PATCH `/api/owner/buildings/:id`
- DELETE `/api/owner/buildings/:id`
- POST `/api/owner/buildings/:buildingId/rooms`
- PATCH `/api/owner/rooms/:id`
- DELETE `/api/owner/rooms/:id`
- POST `/api/owner/rooms/:roomId/availability`
- DELETE `/api/owner/availability/:id`
- PATCH `/api/owner/availability/:id/block`

### Organizer
- GET `/api/organizer/events`
- POST `/api/organizer/events`
- PATCH `/api/organizer/events/:id`
- DELETE `/api/organizer/events/:id`
- POST `/api/organizer/events/:id/duplicate`
- GET `/api/organizer/venues/search?startAt=&endAt=&capacity=&location=&amenities=`
- POST `/api/organizer/bookings`
- PATCH `/api/organizer/bookings/:id/cancel`

### Analytics
- GET `/api/organizer/analytics/overview`

## 4) UI Wireframes (Text)

### Venue Owner Dashboard
- Header: profile + logout
- KPI cards: Buildings, Rooms, Active Slots
- Building list
  - building card
  - nested room list
  - actions: add room, add availability, block slot

### Organizer Dashboard
- Header: profile + logout
- KPI cards: total events, total attendees, upcoming, past
- Events list
  - event card: status, attendees, dates
  - actions: book venue, duplicate template, cancel booking
- Event modal
  - title, description, category, attendees, schedule
  - save draft / publish
- Booking modal
  - filters: location, amenities, capacity/date prefilled
  - available rooms list + select

## 5) Validation & Edge Cases

- No room double booking on same interval
- Capacity must satisfy expected attendees
- Cannot create or book in past
- Cannot delete room/building with active bookings
- Owner cannot modify others' resources
- Organizer cannot book event not owned by self
- Booking cancellation releases slot

## 6) Sample Test Cases

1. Create building/room/availability as venue owner -> succeeds.
2. Add overlapping availability for same room -> fails.
3. Organizer creates event with attendees > room capacity -> booking fails.
4. Two simultaneous booking attempts same room/time -> only one confirmed.
5. Organizer cancels booking -> event booking cleared, slot available.
6. Owner tries deleting room with future confirmed booking -> fails.
7. Duplicate event template -> new draft with copied fields.

