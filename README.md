# Twitter_Engagement_Bait_Modeling

Introduction:
This project is designed to flag X/Twitter posts meant to provoke engagement, whether it be harmless engagement like asking for likes, or harmful posts meant to incite outrage through fake news, provocatory langauge, and more. The data source is the X/Twitter developer platform, where users can make API calls to receive detailed tweet statistics and metadata. Data was stored in a PostgreSQL database, and integrated with Python to clean and organize the data into readable tables. After data cleaning was complete, the data was through different machine learning models, each with their own proper procedure of hyperparameter tuning and training/testing in order to determine the model best at predicting the nature of a tweet.


Tools Used:  
Python (numpy, pandas, matplotlib,scikit-learn, Random Forest, XGBoost, roBERTa)
SQL (PostgreSQL)
 
# Summary

The best performing model in the analysis was the roBERTa model utilizing just the tweet text, without any input from metadata stats (likes, account followers, etc.) Because of the imbalanced nature of the classes within our data (there were significantly more normal tweets than benign/harmful engagement), the macro f1 score was used as our primary indicator of model performance. Our best model had a score of .84, as opposed to an accuracy of .87, which implies the model performs well, but suffers slightly when predicting the minority classes. 

# Implications

In the current state of the world, where anyone can post anything online, being able to correctly identify what is and isn't engagement bait is essential to prevent the spread of misinformation, as well as to help with the ever present cyberbullying that occurs on a daily basis. According to [Harmony Heathcare](https://www.harmonyhit.com/phone-screen-time-statistics/), the average American spends almost 5 hours on their phones a day, and my goal with this project is to limit the amount of time they spend engaging with content meant to provoke their emotions in a negative way by training and deploying a model capable of flagging and/or filtering these types of posts, so users know exactly what they are looking at.

# Limitations

 Lots of tweets collected for this analysis contained some type of media, whether it be a picture, gif, or video. The search criteria for the X API searched for tweets that had text, and didn't care about if they did or didn't have media. The X API allows users to collect media statistics and metadata, such as the type and size of the embedded item, but doesn't perform any actual analysis of the object itself. There is an alt_text column, which would describe what the media elemet is, but that has to be manually added by the tweet author, which many tweets in our database do not have. This was the biggest limitation of the analysis, as the media contained in a tweet can provide a huge amount of additional context to the text included in the tweet in determining its status as bait or not. This would require a much more complicated image/video analysis prompt for the LLM, as well as storing all of the media elemnts from over 7000 tweets in order to be analyzed, with videos needing to be split into single frames. For a personal project with limited time and computing power, this was simply unviable for my analysis, as the time and potential API costs of analyzing and labeling all of those tweets and images would not be friendly.

 Another limitation worth mentioning was the tweet collection itself. As it currently stands, the X/Twitter API doesn't have a method to filter tweets by engagement statistics when collecting tweets. While the purpose of this project is to classify tweets by their content and not engagement statistics, filtering for higher engagement could reveal more tweets from bot/purpseful engagement bait accounts in order to try and alleviate the class imbalance the current analysis contains. Due to the restrictions of the X/Twitter API, out of the 7000 tweets collected, only around 3300 were viable for analysis, as the vast majority of tweets were from extremely small accounts just tweeting normal things. If those tweets were to be included, our class distribution would be skewed even more in favor of no bait, hindering the machine learning model's capabilty of proper prediction.

# Future Improvements

As discussed above, the main improvement that could be made to this project would be the inclusion of tweets simply containing media, as well as proper resources for analyzing said media. With proper computing power and LLM access, a much more robust analysis could be conducted, which would take media context in combination with text context to make an even more educated classification for each tweet. This is especially relevant in the current AI dominated world, as digital media is so easy to create now with AI tools, giving people without previous graphic design skills an easy way to create content, both good or bad. Having a model able to identify and properly classify tweets, especially considering the vast amount of AI generated media on X/Twitter, would be extermely beneficial.

 While the current X/Twitter API doesn't have the right tools to filter for higher engagment tweets, more data collected could always be helpful. Because the X/Twitter API isn't free, I never wanted to collect a lot of data, even though it I know it could be beneficial and potentially help create a stronger model. In the future, with more resources, it is definitely something I'd consider.

# Conclusion
