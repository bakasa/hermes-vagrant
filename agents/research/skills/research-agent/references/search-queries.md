# Research Agent — Search Query Templates

## Query Design Principles

1. **Specific > Broad:** Narrow queries return higher-quality results
2. **Date-bounded:** Always include time constraints for relevance
3. **Source-qualify:** Prefix with site: or source: when targeting specific types
4. **Multi-angle:** Run 3-5 variants of the same question for coverage

---

## Model Development & Training

### LLM Training Techniques
```
"LLM training" AND ("technique" OR "method" OR "approach") AND (2024 OR 2025)
"language model" AND ("fine-tuning" OR "RLHF" OR "DPO" OR "instruction tuning")
"transformer" AND ("training efficiency" OR "scaling" OR "distributed training")
"mixture of experts" AND ("architecture" OR "training" OR "implementation")
```

### Model Evaluation
```
"LLM evaluation" AND ("benchmark" OR "metric" OR "framework")
"language model" AND ("hallucination" OR "factuality" OR "reliability")
"model evaluation" AND ("human evaluation" OR "automated metrics" OR "arena")
```

### Small/Efficient Models
```
"small language model" AND ("compression" OR "distillation" OR "quantization")
"efficient transformer" AND ("inference" OR "deployment" OR "edge")
"on-device AI" AND ("mobile" OR "edge" OR "embedded")
```

---

## NLP & Language Understanding

### Text Generation
```
"text generation" AND ("quality" OR "diversity" OR "controllability")
"language model decoding" AND ("strategy" OR "sampling" OR "beam search")
"creative writing" AND ("AI" OR "language model" OR "GPT")
```

### Information Extraction
```
"named entity recognition" AND ("state of the art" OR "SOTA" OR "benchmark")
"relation extraction" AND ("few-shot" OR "zero-shot" OR "LLM-based")
"information extraction" AND ("document" OR "long-form" OR "structured")
```

### Multilingual NLP
```
"multilingual language model" AND ("cross-lingual" OR "transfer" OR "low-resource")
"machine translation" AND ("neural" OR "LLM-based" OR "document-level")
"language understanding" AND ("multilingual" OR "cross-lingual")
```

---

## Computer Vision

### Vision Models
```
"vision transformer" AND ("architecture" OR "training" OR "efficiency")
"vision language model" AND ("VLM" OR "multimodal" OR "image understanding")
"diffusion model" AND ("image generation" OR "stable diffusion" OR "DALL-E")
```

### Object Detection & Segmentation
```
"object detection" AND ("YOLO" OR "transformer" OR "real-time")
"image segmentation" AND ("SAM" OR "foundation model" OR "zero-shot")
```

### Video Understanding
```
"video understanding" AND ("action recognition" OR "temporal" OR "LLM")
"video generation" AND ("text-to-video" OR "diffusion" OR "Sora")
```

---

## AI Safety & Alignment

### Alignment
```
"AI alignment" AND ("technique" OR "method" OR "framework")
"RLHF" AND ("improvement" OR "limitation" OR "alternative")
"constitutional AI" AND ("training" OR "method" OR "results")
"value alignment" AND ("specification" OR "reward" OR "feedback")
```

### Safety & Robustness
```
"AI safety" AND ("research" OR "benchmark" OR "evaluation")
"adversarial attack" AND ("language model" OR "robustness" OR "defense")
"LLM safety" AND ("jailbreak" OR "prompt injection" OR "alignment")
```

### Interpretability
```
"mechanistic interpretability" AND ("transformer" OR "neural network" OR "circuit")
"explainable AI" AND ("method" OR "evaluation" OR "visualization")
"LLM interpretability" AND ("attention" OR "probe" OR "causal")
```

---

## MLOps & Infrastructure

### Deployment
```
"LLM deployment" AND ("serving" OR "inference" OR "optimization")
"model serving" AND ("vLLM" OR "TGI" OR "tensorrt" OR "ONNX")
"AI infrastructure" AND ("GPU" OR "cluster" OR "scaling" OR "cost")
```

### Data Engineering
```
"training data" AND ("curation" OR "quality" OR "synthetic" OR "filtering")
"data-centric AI" AND ("methodology" OR "tool" OR "pipeline")
"synthetic data" AND ("generation" OR "quality" OR "LLM")
```

### Monitoring
```
"ML monitoring" AND ("drift" OR "performance" OR "production")
"LLM monitoring" AND ("latency" OR "cost" OR "quality" OR "observability")
```

---

## Agents & Tool Use

### AI Agents
```
"AI agent" AND ("tool use" OR "planning" OR "reasoning" OR "autonomous")
"LLM agent" AND ("framework" OR "evaluation" OR "benchmark")
"multi-agent" AND ("coordination" OR "collaboration" OR "communication")
```

### Retrieval & RAG
```
"retrieval augmented generation" AND ("RAG" OR "architecture" OR "evaluation")
"vector database" AND ("search" OR "indexing" OR "similarity" OR "scaling")
"document retrieval" AND ("dense" OR "sparse" OR "hybrid" OR "embedding")
```

---

## Reinforcement Learning

### RL Fundamentals
```
"reinforcement learning" AND ("algorithm" OR "policy" OR "reward")
"RLHF" AND ("language model" OR "feedback" OR "alignment")
"inverse reinforcement learning" AND ("IRL" OR "imitation" OR "reward learning")
```

### RL Applications
```
"reinforcement learning" AND ("robotics" OR "game" OR "control")
"RL for LLM" AND ("fine-tuning" OR "alignment" OR "reward model")
```

---

## Emerging Topics

### Reasoning
```
"chain of thought" AND ("reasoning" OR "prompting" OR "LLM")
"AI reasoning" AND ("logical" OR "mathematical" OR "multi-step")
"o1" OR "o3" OR "reasoning model" AND ("architecture" OR "training" OR "evaluation")
```

### Multimodal AI
```
"multimodal" AND ("language" OR "vision" OR "audio" OR "model")
"audio language model" AND ("speech" OR "understanding" OR "generation")
"embodied AI" AND ("robot" OR "vision" OR "action" OR "simulation")
```

### Code Generation
```
"code generation" AND ("LLM" OR "benchmark" OR "evaluation")
"automated programming" AND ("code completion" OR "bug fixing" OR "testing")
"software engineering" AND ("AI" OR "LLM" OR "automated")
```

### AI for Science
```
"AI for science" AND ("drug discovery" OR "material" OR "biology" OR "climate")
"scientific discovery" AND ("machine learning" OR "neural network" OR "AI")
"protein structure" AND ("AlphaFold" OR "prediction" OR "AI")
```

---

## Competitive Intelligence

### Model Releases
```
"new AI model" AND ("release" OR "announcement" OR "benchmark") AND (2024 OR 2025)
"open source" AND ("language model" OR "LLM" AND "release")
"model card" AND ("release" OR "benchmark" OR "capability")
```

### Industry Trends
```
"AI industry" AND ("trend" OR "market" OR "investment" OR "regulation")
"artificial intelligence" AND ("regulation" OR "policy" OR "law" OR "EU AI Act")
"open source AI" AND ("debate" OR "definition" OR "policy" OR "community")
```

---

## arXiv-Specific Query Templates

### By Category
```
cat:cs.AI AND (abs:"language model" OR abs:"neural network")
cat:cs.CL AND (abs:"NLP" OR abs:"text generation")
cat:cs.LG AND (abs:"deep learning" OR abs:"reinforcement learning")
cat:cs.CV AND (abs:"vision" OR abs:"image")
cat:stat.ML AND (abs:"Bayesian" OR abs:"probabilistic")
```

### By Recurrence
```
cat:cs.LG AND submittedDate:[202501010000 TO 202512312359]
cat:cs.AI AND (abs:"transformer" OR abs:"attention") AND submittedDate:[THIS_MONTH]
```

### Trending Papers
```
cat:cs.LG AND (abs:"state of the art" OR abs:"SOTA" OR abs:"outperform")
cat:cs.CL AND (abs:"benchmark" OR abs:"evaluation" OR abs:"leaderboard")
```

---

## Search Best Practices

1. **Always date-bound:** Add `AND (2024 OR 2025)` or date ranges
2. **Iterate:** Start broad, refine based on initial results
3. **Cross-reference:** Verify findings across 2+ sources minimum
4. **Track queries:** Log which queries have been run to avoid duplication
5. **Save results:** Store raw search results alongside processed findings
6. **Note search date:** Always record when a query was run
