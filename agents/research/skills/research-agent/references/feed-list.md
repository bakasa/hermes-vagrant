# Research Agent — RSS Feed Sources

## Machine Learning & AI Research

| Feed | URL | Category | Reliability |
|------|-----|----------|-------------|
| Hugging Face Blog | https://huggingface.co/blog/feed.xml | models/datasets | HIGH |
| Google AI Blog | https://ai.googleblog.com/feeds/posts/default | research | HIGH |
| DeepMind Blog | https://www.deepmind.com/blog/rss.xml | research | HIGH |
| OpenAI Blog | https://openai.com/blog/rss.xml | research/products | HIGH |
| BAIR Blog | https://bair.berkeley.edu/blog/feed.xml | research | HIGH |
| AWS ML Blog | https://aws.amazon.com/blogs/machine-learning/feed/ | industry | MEDIUM |
| Microsoft Research | https://www.microsoft.com/en-us/research/feed/ | research | HIGH |
| Meta AI Blog | https://ai.meta.com/blog/rss/ | research | HIGH |
| Apple ML Research | https://machinelearning.apple.com/rss.xml | research | MEDIUM |
| NVIDIA AI Blog | https://blogs.nvidia.com/feed/ | industry/tech | MEDIUM |

## Newsletters (RSS)

| Feed | URL | Category | Reliability |
|------|-----|----------|-------------|
| Import AI (Jack Clark) | https://importai.substack.com/feed | newsletter | HIGH |
| The Batch (DeepLearning.AI) | https://www.deeplearning.ai/the-batch/feed/ | newsletter | HIGH |
| TLDR AI | https://tldr.tech/ai/newsletter | newsletter | MEDIUM |
| The Gradient | https://thegradient.substack.com/feed | newsletter | HIGH |
| AI Weekly | https://aiweekly.co/feed.xml | newsletter | MEDIUM |
| NLP News (Sebastian Ruder) | https://www.ruder.io/nlp-news/rss.xml | newsletter | HIGH |
| Semiengineering AI | https://semiengineering.com/category/ai/feed/ | industry | MEDIUM |

## Tech & Industry

| Feed | URL | Category | Reliability |
|------|-----|----------|-------------|
| Hacker News (AI) | https://hnrss.org/newest?q=AI+OR+ML+OR+GPT&count=25 | discussion | MEDIUM |
| TechCrunch AI | https://techcrunch.com/category/artificial-intelligence/feed/ | news | MEDIUM |
| The Verge AI | https://www.theverge.com/ai-artificial-intelligence/rss/index.xml | news | MEDIUM |
| Ars Technica AI | https://feeds.arstechnica.com/arstechnica/index | news | MEDIUM |
| MIT Tech Review AI | https://www.technologyreview.com/feed/ | news | HIGH |
| Wired AI | https://www.wired.com/feed/tag/ai/latest/rss | news | MEDIUM |
| VentureBeat AI | https://venturebeat.com/category/ai/feed/ | news | MEDIUM |

## Academic & Preprints

| Feed | URL | Category | Reliability |
|------|-----|----------|-------------|
| arXiv cs.AI | https://rss.arxiv.org/rss/cs.AI | preprint | HIGH |
| arXiv cs.CL | https://rss.arxiv.org/rss/cs.CL | preprint | HIGH |
| arXiv cs.LG | https://rss.arxiv.org/rss/cs.LG | preprint | HIGH |
| arXiv cs.CV | https://rss.arxiv.org/rss/cs.CV | preprint | HIGH |
| arXiv stat.ML | https://rss.arxiv.org/rss/stat.ML | preprint | HIGH |
| Semantic Scholar (trending) | https://api.semanticscholar.org/graph/v1/paper/search?fields=title,url | papers | HIGH |

## Open Source & Tools

| Feed | URL | Category | Reliability |
|------|-----|----------|-------------|
| GitHub Trending (Python) | https://github.com/trending/python?since=daily | repos | MEDIUM |
| GitHub Trending (All) | https://github.com/trending?since=daily | repos | MEDIUM |
| LangChain Blog | https://blog.langchain.dev/rss/ | tools | MEDIUM |
| LlamaIndex Blog | https://www.llamaindex.ai/rss.xml | tools | MEDIUM |
| Weights & Biases Blog | https://wandb.ai/fully-connected/rss.xml | tools | MEDIUM |

## Individual Researchers & Labs

| Feed | URL | Category | Reliability |
|------|-----|----------|-------------|
| Andrej Karpathy | https://karpathy.ai/rss.xml | research | HIGH |
| Yann LeCun | https://www.facebook.com/yann.lecun/posts/rss | research | MEDIUM |
| François Chollet | https://fchollet.substack.com/feed | newsletter | HIGH |
| Lil'Log (Lilian Weng) | https://lilianweng.github.io/lil-log/feed.xml | research | HIGH |
| Distill | https://distill.pub/rss.xml | visual-explanations | HIGH |
| Jay Alammar | https://jalammar.github.io/feed.xml | explainers | HIGH |
| Christopher Olah | https://colah.github.io/rss.xml | explainers | HIGH |

## Feeds Configuration Notes

- **Scan Frequency:** All feeds scanned at 06:00 UTC daily + 6h extract cycle
- **Timeout:** 30 seconds per feed
- **Max Entries:** 15 per feed per scan (prioritize most recent)
- **Retry:** 2 retries with exponential backoff
- **Failure Handling:** Mark feed as DEAD after 5 consecutive failures; alert in daily digest

## Adding New Feeds

When adding a new feed:
1. Verify RSS/XML is valid (use `xmllint` or feed validator)
2. Test fetch with `curl -I <url>` (check for 200 + correct Content-Type)
3. Add to this file with category and initial reliability assessment
4. Set initial reliability to LOW; promote after 30 days of successful scans
