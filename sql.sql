create database stackoverflow DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

use stackoverflow;

create table badges (
  Id INT NOT NULL PRIMARY KEY,
  UserId INT,
  Name VARCHAR(50),
  Date DATETIME
);

CREATE TABLE comments (
    Id INT NOT NULL PRIMARY KEY,
    PostId INT NOT NULL,
    Score INT NOT NULL DEFAULT 0,
    Text TEXT,
    CreationDate DATETIME,
    UserId INT NOT NULL
);

CREATE TABLE post_history (
    Id INT NOT NULL PRIMARY KEY,
    PostHistoryTypeId SMALLINT NOT NULL,
    PostId INT NOT NULL,
    RevisionGUID VARCHAR(36),
    CreationDate DATETIME,
    UserId INT NOT NULL,
    Text TEXT
);
CREATE TABLE post_links (
  Id INT NOT NULL PRIMARY KEY,
  CreationDate DATETIME DEFAULT NULL,
  PostId INT NOT NULL,
  RelatedPostId INT NOT NULL,
  LinkTypeId INT DEFAULT NULL
);


CREATE TABLE posts (
    Id INT NOT NULL PRIMARY KEY,
    PostTypeId SMALLINT,
    AcceptedAnswerId INT,
    ParentId INT,
    Score INT NULL,
    ViewCount INT NULL,
    Body text NULL,
    OwnerUserId INT NOT NULL,
    LastEditorUserId INT,
    LastEditDate DATETIME,
    LastActivityDate DATETIME,
    Title varchar(256) NOT NULL,
    Tags VARCHAR(256),
    AnswerCount INT NOT NULL DEFAULT 0,
    CommentCount INT NOT NULL DEFAULT 0,
    FavoriteCount INT NOT NULL DEFAULT 0,
    CreationDate DATETIME,
    jsonData json
);

CREATE TABLE tags (
  Id INT NOT NULL PRIMARY KEY,
  TagName VARCHAR(50) CHARACTER SET latin1 DEFAULT NULL,
  Count INT DEFAULT NULL,
  ExcerptPostId INT DEFAULT NULL,
  WikiPostId INT DEFAULT NULL
);


CREATE TABLE users (
    Id INT NOT NULL PRIMARY KEY,
    Reputation INT NOT NULL,
    CreationDate DATETIME,
    DisplayName VARCHAR(50) NULL,
    LastAccessDate  DATETIME,
    Views INT DEFAULT 0,
    WebsiteUrl VARCHAR(256) NULL,
    Location VARCHAR(256) NULL,
    AboutMe TEXT NULL,
    Age INT,
    UpVotes INT,
    DownVotes INT,
    EmailHash VARCHAR(32)
);

CREATE TABLE votes (
    Id INT NOT NULL PRIMARY KEY,
    PostId INT NOT NULL,
    VoteTypeId SMALLINT,
    CreationDate DATETIME
);

    LOAD XML LOCAL INFILE 'Badges.xml' INTO TABLE badges ROWS IDENTIFIED by '<row>';

    LOAD XML LOCAL INFILE 'Comments.xml' INTO TABLE comments ROWS IDENTIFIED by '<row>';

    LOAD XML LOCAL INFILE 'PostHistory.xml' INTO TABLE post_history ROWS IDENTIFIED by '<row>';

    LOAD XML LOCAL INFILE 'PostLinks.xml' INTO TABLE post_links ROWS IDENTIFIED BY '<row>';

    LOAD XML LOCAL INFILE 'Posts.xml' INTO TABLE posts ROWS IDENTIFIED by '<row>';

    LOAD XML LOCAL INFILE 'Tags.xml' INTO TABLE tags ROWS IDENTIFIED BY '<row>';

    LOAD XML LOCAL INFILE 'Users.xml' INTO TABLE users ROWS IDENTIFIED by '<row>';

    LOAD XML LOCAL INFILE 'Votes.xml' INTO TABLE votes ROWS IDENTIFIED by '<row>';

create index badges_idx_1 on badges(UserId);

create index comments_idx_1 on comments(PostId);
create index comments_idx_2 on comments(UserId);

create index post_history_idx_1 on post_history(PostId);
create index post_history_idx_2 on post_history(UserId);

create index posts_idx_1 on posts(AcceptedAnswerId);
create index posts_idx_2 on posts(ParentId);
create index posts_idx_3 on posts(OwnerUserId);
create index posts_idx_4 on posts(LastEditorUserId);

create index votes_idx_1 on votes(PostId);

DELIMITER //
CREATE PROCEDURE `denormalizeComments` (in postID int(11))
BEGIN
  UPDATE posts SET jsonData=(SELECT JSON_ARRAYAGG(JSON_OBJECT('id', Id, 'post_id', PostId, 'score', Score, 'text', Text, 'created_at', CreationDate, 'user_id', UserId)) FROM comments WHERE PostId=postID) WHERE Id=postID;
END //
DELIMITER ;


DELIMITER //
CREATE trigger `appendJsonComment` AFTER INSERT ON comments
FOR EACH ROW BEGIN
    update posts set jsonData=JSON_ARRAY_APPEND(jsonData, '$', (SELECT JSON_OBJECT('id', Id, 'post_id', PostId, 'score', Score, 'text', Text, 'created_at', CreationDate, 'user_id', UserId) FROM comments WHERE Id=NEW.Id)) WHERE Id=NEW.PostId;
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE `addComment` (in Id int(11), in PostId int(11), in Score int(11), in Text text, in CreationDate datetime, in UserId int(11))
BEGIN
  INSERT INTO comments VALUES(Id, PostId, Score, Text, CreationDate, UserId);
  update posts set jsonData=JSON_ARRAY_APPEND(jsonData, '$', (SELECT JSON_OBJECT('id', Id, 'post_id', PostId, 'score', Score, 'text', Text, 'created_at', CreationDate, 'user_id', UserId) FROM comments WHERE Id=last_insert_id())) WHERE Id=PostId;
END //
DELIMITER ;