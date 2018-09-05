require 'sqlite3'
require 'singleton'

class UserDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('students.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_accessor :fname, :lname

  def self.all
    data = UserDBConnection.instance.execute("SELECT * FROM users")
    data.map { |datum| User.new(datum) }
  end

  def self.find_by_id(id)
    user = UserDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil unless user.length > 0

    User.new(user.first) # play is stored in an array!
  end

  def self.find_by_name(fname, lname)

    user = UserDBConnection.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL
    return nil unless user.length > 0
    
    User.new(user.first) 
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end
  
  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end 
  
  def followed_questions
    QuestionFollows.followed_questions_for_user_id(@id)
  end 
  
  def authored_questions
    Question.find_by_author_id(@id)
  end 
  
  def authored_replies
    Reply.find_by_user_id(@id)
  end 
end

class Question
  attr_accessor :title, :body, :author_id

  def self.all
    data = UserDBConnection.instance.execute("SELECT * FROM questions")
    data.map { |datum| Question.new(datum) }
  end

  def self.find_by_author_id(author_id)
    question = UserDBConnection.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL
    return nil unless question.length > 0
    result = []
    question.each do |quest|
      result << Question.new(quest)
    end 
    result 
  end
  
  def self.most_followed(n)
    QuestionFollows.most_followed_questions(n)
  end
  
  def self.find_by_id(id)
    question = UserDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    return nil unless question.length > 0

    Question.new(question.first) # play is stored in an array!
  end

  def initialize(options)
    @question_id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end
  
  def self.most_liked(n)
    question = UserDBConnection.instance.execute(<<-SQL, n)
    SELECT
      
    FROM
    
    WHERE
    
    GROUP BY
    
    LIMIT n
    SQL
    question
  end
  
  def likers 
    QuestionLike.likers_for_question_id(@question_id)
  end 
  
  def num_likes 
    QuestionLike.num_likes_for_question_id(@question_id)
  end 
  
  def followers 
    QuestionFollows.followers_for_question_id(@question_id)
  end 
  
  def author 
    question = UserDBConnection.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        users 
      WHERE
        id = @author_id
    SQL
    question 
  end 
  
  def replies 
    Reply.find_by_question_id(@question_id)
  end 
end

class QuestionFollows 
  attr_accessor :user_id, :question_id

  def self.all
    data = UserDBConnection.instance.execute("SELECT * FROM question_follows")
    data.map { |datum| QuestionFollows.new(datum) }
  end

  def self.find_by_id(id)
    questionfollows = UserDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        id = ?
    SQL
    return nil unless questionfollows.length > 0

    QuestionFollows.new(questionfollows.first) # play is stored in an array!
  end
  
  def self.most_followed_questions(n)
    questionfollows = UserDBConnection.instance.execute(<<-SQL, n)
      SELECT
        title, count(questions.id)
      FROM
        questions
      LEFT JOIN
       question_follows ON questions.id = question_follows.question_id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(questions.id) DESC
      LIMIT
        ?
    SQL
    return questionfollows
  end
  
  def self.followers_for_question_id(question_id)
    questionfollows = UserDBConnection.instance.execute(<<-SQL, question_id)
      SELECT 
        users.id, fname, lname 
      FROM
        users 
      LEFT JOIN question_follows 
      ON users.id = question_follows.user_id
      WHERE 
        question_follows.question_id = ?  
    SQL
    result = []
    questionfollows.each do |el|
      result << User.new(el)
    end 
    result 
  end 
  
  def self.followed_questions_for_user_id(user_id)
    questionfollows = UserDBConnection.instance.execute(<<-SQL, user_id)
      SELECT 
        *
      FROM
        questions  
      LEFT JOIN question_follows 
      ON questions.id = question_follows.question_id 
      WHERE 
      user_id = ?
      SQL
      result = []
      questionfollows.each do |el|
        result << Question.new(el)
      end 
      result
    end 

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
end

class Reply
  attr_accessor :question_id, :parent_reply_id, :author_id, :body

  def self.all
    data = UserDBConnection.instance.execute("SELECT * FROM replies")
    data.map { |datum| Reply.new(datum) }
  end
  
  def self.find_by_user_id(author_id)
    reply = UserDBConnection.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        replies
      WHERE
        author_id = ?
    SQL
    return nil unless reply.length > 0
    result = []
    reply.each do |re|
      result << Reply.new(re)
    end 
    result
  end
  
  def self.find_by_question_id(question_id)
    reply = UserDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
    return nil unless reply.length > 0
    
    replies = []
    reply.each do |reply|
      replies << Reply.new(reply)
    end
    
    replies
  end

  def self.find_by_id(id)
    reply = UserDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    return nil unless reply.length > 0

    Reply.new(reply.first) # play is stored in an array!
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_reply_id = options['parent_reply_id']
    @author_id = options['author_id']
    @body = options['body']
  end
  
  def author 
    question = UserDBConnection.instance.execute(<<-SQL, @author_id)
      SELECT
        *
      FROM
        users 
      WHERE
        id = ?
    SQL
    question 
  end 
  
  def question 
    question = UserDBConnection.instance.execute(<<-SQL, @question_id)
      SELECT
        *
      FROM
        questions 
      WHERE
        id = ?
    SQL
    question 
  end 
  
  def parent_reply 
    question = UserDBConnection.instance.execute(<<-SQL, @parent_reply_id)
      SELECT
        *
      FROM
        replies 
      WHERE
        id = ? 
    SQL
    question
  end 
  
  def child_replies
    question = UserDBConnection.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies  
      WHERE
        parent_reply_id = ?
    SQL
    question
  end 
end

class QuestionLike
  def self.likers_for_question_id(quest)
    question = UserDBConnection.instance.execute(<<-SQL, quest)
      SELECT
        users.fname AS liker
      FROM
        question_likes 
      LEFT JOIN users 
      ON question_likes.user_id = users.id 
      WHERE question_id = ?
    SQL
    question
  end 
  
  def self.num_likes_for_question_id(quest)
    question = UserDBConnection.instance.execute(<<-SQL, quest)
      SELECT
        COUNT(user_id) AS number_of_likes 
      FROM
        question_likes  
      WHERE question_id = ?
    SQL
    question
  end 
  
  def self.liked_questions_for_user_id(user_id)
    question = UserDBConnection.instance.execute(<<-SQL, user_id)
    SELECT 
      * 
    FROM 
      questions 
    LEFT JOIN question_likes 
    ON question_likes.user_id = questions.author_id
    WHERE 
    questions.author_id = ?
  SQL
  question
  end
  
  def self.most_liked_questions(n)
    question = UserDBConnection.instance.execute(<<-SQL, n)
    SELECT
      title
    FROM
      questions
    LEFT JOIN
      question_likes 
      ON questions.id = question_likes.question_id
    GROUP BY
      question_likes.question_id
    ORDER BY
      COUNT(question_likes.user_id) DESC
    LIMIT ?
    SQL
    
    question
  end
end 
