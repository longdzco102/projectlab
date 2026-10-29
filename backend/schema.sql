-- PostgreSQL Schema for Xianxia Chat (Tiên Giới Hội)

CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  avatar_url VARCHAR(1000) DEFAULT NULL,
  avatar_path VARCHAR(500) DEFAULT NULL,
  realm VARCHAR(50) DEFAULT 'Luyện Khí Kỳ',
  realm_index SMALLINT DEFAULT 0,
  exp BIGINT DEFAULT 0,
  status VARCHAR(20) DEFAULT 'offline',
  role VARCHAR(20) DEFAULT 'user',
  gender VARCHAR(20) DEFAULT 'kho_noi',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sects (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  icon VARCHAR(10) DEFAULT '🐉',
  description TEXT DEFAULT NULL,
  banner_url VARCHAR(1000) DEFAULT NULL,
  banner_path VARCHAR(500) DEFAULT NULL,
  owner_id BIGINT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_sects_owner ON sects (owner_id);

CREATE TABLE IF NOT EXISTS sect_members (
  id BIGSERIAL PRIMARY KEY,
  sect_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  role VARCHAR(20) DEFAULT 'de_tu',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_sect_user UNIQUE (sect_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_sect_members_sect ON sect_members (sect_id);
CREATE INDEX IF NOT EXISTS idx_sect_members_user ON sect_members (user_id);

CREATE TABLE IF NOT EXISTS channels (
  id BIGSERIAL PRIMARY KEY,
  sect_id BIGINT NOT NULL,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(20) DEFAULT 'text',
  icon VARCHAR(10) DEFAULT '#',
  position INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_channels_sect ON channels (sect_id);

CREATE TABLE IF NOT EXISTS messages (
  id BIGSERIAL PRIMARY KEY,
  channel_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  content TEXT NOT NULL,
  type VARCHAR(20) DEFAULT 'text',
  file_url VARCHAR(1000) DEFAULT NULL,
  file_path VARCHAR(500) DEFAULT NULL,
  file_name VARCHAR(255) DEFAULT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_messages_channel_time ON messages (channel_id, created_at);

CREATE TABLE IF NOT EXISTS message_reactions (
  message_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  emoji VARCHAR(10) NOT NULL,
  PRIMARY KEY (message_id, user_id, emoji)
);

CREATE TABLE IF NOT EXISTS direct_messages (
  id BIGSERIAL PRIMARY KEY,
  sender_id BIGINT NOT NULL,
  receiver_id BIGINT NOT NULL,
  content TEXT NOT NULL,
  type VARCHAR(20) DEFAULT 'text',
  file_url VARCHAR(1000) DEFAULT NULL,
  file_path VARCHAR(500) DEFAULT NULL,
  file_name VARCHAR(255) DEFAULT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  is_read SMALLINT DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_dm_sender_receiver ON direct_messages (sender_id, receiver_id, created_at);
CREATE INDEX IF NOT EXISTS idx_dm_receiver_created ON direct_messages (receiver_id, created_at);

CREATE TABLE IF NOT EXISTS posts (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  excerpt VARCHAR(500) DEFAULT NULL,
  cover_url VARCHAR(1000) DEFAULT NULL,
  cover_path VARCHAR(500) DEFAULT NULL,
  tag VARCHAR(50) DEFAULT 'tu-luyen',
  icon VARCHAR(10) DEFAULT '📖',
  views INT DEFAULT 0,
  likes INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_posts_tag ON posts (tag);
CREATE INDEX IF NOT EXISTS idx_posts_user ON posts (user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created ON posts (created_at);

CREATE TABLE IF NOT EXISTS post_comments (
  id BIGSERIAL PRIMARY KEY,
  post_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_post_comments_post ON post_comments (post_id);

CREATE TABLE IF NOT EXISTS post_likes (
  post_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  PRIMARY KEY (post_id, user_id)
);

CREATE TABLE IF NOT EXISTS notifications (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  type VARCHAR(50) DEFAULT 'system',
  is_read SMALLINT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications (user_id);

CREATE TABLE IF NOT EXISTS user_friends (
  user_id BIGINT NOT NULL,
  friend_id BIGINT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, friend_id)
);
CREATE INDEX IF NOT EXISTS idx_user_friends_friend ON user_friends (friend_id);

CREATE TABLE IF NOT EXISTS user_blocks (
  user_id BIGINT NOT NULL,
  blocked_user_id BIGINT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, blocked_user_id)
);

-- Trigger for auto-updating updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_posts_updated_at ON posts;
CREATE TRIGGER trg_posts_updated_at BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
