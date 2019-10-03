_askubuntu.com data from https://archive.org/details/stackexchange_

# Exercise 1
The following query creates a stored procedure denormalizeComments(postID) that moves all comments for a post (the parameter) into a json array on the post:
```sql
DELIMITER //
CREATE PROCEDURE `denormalizeComments` (in postID int(11))
BEGIN
  UPDATE `posts` SET jsonData=(SELECT JSON_ARRAYAGG(JSON_OBJECT('id', Id, 'post_id', PostId, 'score', Score, 'text', Text, 'created_at', CreationDate, 'user_id', UserId)) FROM comments WHERE PostId=postID) WHERE Id=postID;
END //
DELIMITER ;
```

# Exercise 2
The following query creates a trigger that inserts newly added comments to the specific post's json array:
```sql
DELIMITER //
CREATE trigger `appendJsonComment` AFTER INSERT ON comments
FOR EACH ROW BEGIN
    update `posts` set jsonData=JSON_ARRAY_APPEND(jsonData, '$', (SELECT JSON_OBJECT('id', Id, 'post_id', PostId, 'score', Score, 'text', Text, 'created_at', CreationDate, 'user_id', UserId) FROM comments WHERE Id=NEW.Id)) WHERE Id=NEW.PostId;
END //
DELIMITER ;
```

# Exercise 3
The following query creates a stored procedure which adds a comment to a post - adding it both to the comment table and the json array:
```sql
DELIMITER //
CREATE PROCEDURE `addComment` (in Id int(11), in PostId int(11), in Score int(11), in Text text, in CreationDate datetime, in UserId int(11))
BEGIN
  INSERT INTO `comments` VALUES(Id, PostId, Score, Text, CreationDate, UserId);
  update `posts` set jsonData=JSON_ARRAY_APPEND(jsonData, '$', (SELECT JSON_OBJECT('id', Id, 'post_id', PostId, 'score', Score, 'text', Text, 'created_at', CreationDate, 'user_id', UserId) FROM comments WHERE Id=last_insert_id())) WHERE Id=PostId;
END //
DELIMITER ;
```

# Exercise 4
The following query creates a view that has json objects with questions and answeres with the display name of the user, the text body, and the score:
```sql
CREATE VIEW `questions_answers` AS SELECT JSON_OBJECT('poster_name', `poster`.`DisplayName`, 'post_text', `posts`.`Body`, 'post_score', `posts`.`Score`, 'commentor_name', `commentor`.`DisplayName`, 'comment_text', `comments`.`Text`, 'comment_score', `comments`.`Score`) as jsonData FROM `posts` INNER JOIN `comments` ON `posts`.`AcceptedAnswerId`=`comments`.`Id` INNER JOIN `users` as `poster` ON `posts`.`OwnerUserId`=`poster`.`Id` INNER JOIN `users` as `commentor` ON `comments`.`UserId`=`commentor`.`Id`;
```
To use the view we can use a query simillar to the following:
```sql
SELECT * FROM `questions_answers`;
```

# Exercise 5
Using the view from exercise 4, the following query creates a stored procedure with one parameter `keyword`, which returns all posts where the keyword appears in the post text and the comment text.
```sql
DELIMITER //
CREATE PROCEDURE `search_qa` (in q_term varchar(255))
BEGIN
  SELECT * FROM `questions_answers` WHERE jsonData->"$.post_text" LIKE CONCAT('%', q_term, '%') AND jsonData->"$.comment_text" LIKE CONCAT('%', q_term, '%');
END //
DELIMITER ;
```
To use the stored procedure we can use a query simillar to the following:
```sql
call search_qa("Just my luck")
```
