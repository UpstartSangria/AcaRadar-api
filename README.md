# AcaRadar 
Application that allows researchers to find innovative research topics from other domains. 

**Please note that this project uses both Ruby & Python**

## Overview
AcaRadar will pull data from arXiv's API using **query** entity, to fetch **paper** entity, which include **summary**, **authors**, **categories** and **links**.

It will then preprocess the text data and 
1. Extract keywords from **summary** of the the paper as **concepts** 
2. Use word embedding to tranform keywords to **embeddings**
3. Use **algorithm** to show the concepts in 2D space 

We hope this tool will give researchers a quick overview of research trends in their own and other domains, and inspire them to explore innovative research topics.

## Objectives
### Short-term usability goals
1. Preprocess text data and generate embeddings
2. Define n-gram frequency algo for word cloud 
3. Define clustering algo to define the distance between each n-gram 
4. Define intersection between different domains

### Long-term goals
1. Speed up the embedding generation process


### Setup

- Copy `config/secrets_example.yml` to `config/secrets.yml` 
- Ensure correct version of Ruby install (see .`ruby-version` for `rbenv`)
- Run `gem install bundler` to install bundler
- Run `bundle install` to install ruby dependencies
- Run `python3 -m venv .venv` to create a virtual environment
- Run `source .venv/bin/activate` to activate the virtual environment
- Run `python -m pip install -r requirements.txt` to install python dependencies
- Run `ruby bin/fetch_arxiv_papers.rb` to fetch papers from arXiv API and store them in the database
- Run `rake run` to run the application

## Running tests
### To run tests:
```bash
rake spec
```

### To test code quality:
```bash
rake quality:all
```

### To run migration:
```bash
RACK_ENV=development rake db:migrate
RACK_ENV=test rake db:migrate
```

### To run the app:
```bash
rake run
```

### To test orm:
```bash
rake console 
# pry(main)> AcaRadar::Database::PaperOrm.all
```

### To delete the database:
```bash
RACK_ENV=development rake db:drop
RACK_ENV=test rake db:drop
```

### To test api

1. Start fresh — delete any old cookie file
```bash
rm -f /tmp/acaradar_cookie.jar
```

2. Start the server
```bash
rake run
```

3. POST your research interest (this sets the session)
```bash
curl -X POST http://localhost:9292/api/v1/research_interest \
     -H "Content-Type: application/json" \
     -d '{"research_interest": "machine learning"}' \
     --cookie-jar /tmp/acaradar_cookie.jar \
     -w "\nHTTP Status: %{http_code}\n" \
     --silent

# {"term":"machine learning","vector_2d":{"x":-0.024392,"y":0.003244}}
# HTTP Status: 201
```

4. GET the papers — reusing the same session cookie
```bash
curl "http://localhost:9292/api/v1/papers?journals%5B%5D=MIS+Quarterly&journals%5B%5D=Management+Science&page=1"   --cookie /tmp/acaradar_cookie.jar -w "\nHTTP Status: %{http_code}\n"

# {"research_interest_term":"machine learning","research_interest_2d":[-0.024391869083046913,0.0032444987446069717],"journals":["MIS Quarterly","Management Science"],"papers":{"data":[{"origin_id":"http://arxiv.org/abs/1702.08072v1","title":"Knowledge Reuse for Customization: Metamodels in an Open Design Community for 3d Printing","abstract" ...
# ...
# "pdf_url":"https://arxiv.org/pdf/1108.4098v1","published_at":"2011-08-20T07:43:46+08:00","authors":"","similarity_score":null}]},"pagination":{"current":1,"total_pages":2,"total_count":15,"prev_page":null,"next_page":2}}
# HTTP Status: 200
```