-- Seed Data: Interesting Tech Ecosystem Data

-- Companies
INSERT INTO companies (name, ticker, sector, country, founded_year, market_cap_billion, employee_count, description, website, is_public) VALUES
('Anthropic', NULL, 'Artificial Intelligence', 'USA', 2021, 18.4, 850, 'AI safety company building reliable, interpretable, and steerable AI systems. Creators of Claude.', 'anthropic.com', false),
('OpenAI', NULL, 'Artificial Intelligence', 'USA', 2015, 80.0, 1700, 'AI research lab known for GPT series, DALL-E, and ChatGPT. Pioneer in large language models.', 'openai.com', false),
('NVIDIA', 'NVDA', 'Semiconductors', 'USA', 1993, 2200.0, 29600, 'Dominant GPU manufacturer powering modern AI workloads. CUDA ecosystem transformed deep learning.', 'nvidia.com', true),
('Mistral AI', NULL, 'Artificial Intelligence', 'France', 2023, 6.0, 200, 'European AI lab producing efficient open-weight language models. Champions open-source AI.', 'mistral.ai', false),
('DeepMind', NULL, 'Artificial Intelligence', 'UK', 2010, NULL, 2000, 'Alphabet subsidiary behind AlphaGo, AlphaFold, and Gemini. Combining neuroscience and ML.', 'deepmind.com', false),
('Hugging Face', NULL, 'AI Infrastructure', 'USA', 2016, 4.5, 350, 'The GitHub of machine learning. Hub for open-source models, datasets, and ML tools.', 'huggingface.co', false),
('Vercel', NULL, 'Developer Tools', 'USA', 2015, 3.25, 500, 'Frontend cloud platform. Popularized edge computing and JAMstack deployment at scale.', 'vercel.com', false),
('HashiCorp', 'HCP', 'DevOps', 'USA', 2012, 6.4, 2400, 'Infrastructure-as-code pioneers. Terraform, Vault, Consul define modern cloud infrastructure.', 'hashicorp.com', true),
('Cloudflare', 'NET', 'Networking', 'USA', 2009, 32.0, 3800, 'Global network edge platform. Security, performance, and serverless at the network layer.', 'cloudflare.com', true),
('Databricks', NULL, 'Data & Analytics', 'USA', 2013, 43.0, 6000, 'Unified data intelligence platform. Created Apache Spark and the Lakehouse architecture.', 'databricks.com', false),
('Stripe', NULL, 'Fintech', 'USA', 2010, 65.0, 8000, 'Internet payments infrastructure. Trusted by millions of businesses worldwide.', 'stripe.com', false),
('Linear', NULL, 'Developer Tools', 'USA', 2019, 0.4, 50, 'Issue tracking for high-performance teams. Famous for sub-50ms UI and opinionated workflow.', 'linear.app', false),
('Temporal', NULL, 'Developer Tools', 'USA', 2019, 0.8, 250, 'Durable execution platform. Makes distributed workflows reliable and observable.', 'temporal.io', false),
('Weaviate', NULL, 'AI Infrastructure', 'Netherlands', 2019, 0.2, 200, 'Open-source vector database built for AI-native applications and semantic search.', 'weaviate.io', false),
('Qdrant', NULL, 'AI Infrastructure', 'Germany', 2021, 0.1, 80, 'High-performance vector similarity search engine written in Rust.', 'qdrant.tech', false),
('PlanetScale', NULL, 'Databases', 'USA', 2018, 0.5, 180, 'MySQL-compatible serverless database with branching workflow for schema changes.', 'planetscale.com', false),
('Neon', NULL, 'Databases', 'USA', 2021, 0.3, 100, 'Serverless Postgres with branching, autoscaling, and scale-to-zero capabilities.', 'neon.tech', false),
('Fly.io', NULL, 'Infrastructure', 'USA', 2017, 0.2, 60, 'Run full-stack apps globally. Deploys Docker containers close to users worldwide.', 'fly.io', false),
('Modal', NULL, 'AI Infrastructure', 'USA', 2021, 0.15, 40, 'Cloud compute for AI/ML. Run Python functions serverlessly with GPU access.', 'modal.com', false),
('Replicate', NULL, 'AI Infrastructure', 'USA', 2019, 0.35, 70, 'Run and fine-tune open-source ML models via API. Democratizing AI deployment.', 'replicate.com', false);

-- Products
INSERT INTO products (company_id, name, category, launch_year, version, description, tags, rating, monthly_active_users_million) VALUES
(1, 'Claude', 'Language Model', 2023, '3.5 Sonnet', 'Constitutional AI-trained assistant. Excels at reasoning, coding, and creative tasks with strong safety properties.', ARRAY['LLM','AI','assistant','safety'], 4.8, 10.0),
(2, 'ChatGPT', 'AI Assistant', 2022, '4o', 'Conversational AI interface built on GPT-4. Most widely adopted consumer AI product globally.', ARRAY['LLM','AI','chatbot','GPT'], 4.6, 180.0),
(2, 'GPT-4o', 'Language Model', 2024, 'gpt-4o', 'Omni multimodal model. Processes text, images, and audio in real-time with human-level response speed.', ARRAY['LLM','multimodal','vision','audio'], 4.7, NULL),
(3, 'H100 GPU', 'Hardware', 2022, 'SXM5', 'Flagship AI accelerator. 80GB HBM3 memory, 3.35 TB/s bandwidth. The gold standard for LLM training.', ARRAY['GPU','hardware','AI','training','inference'], 4.9, NULL),
(3, 'CUDA', 'Developer Platform', 2007, '12.3', 'Parallel computing platform enabling GPU-accelerated AI and scientific computing.', ARRAY['GPU','parallel','computing','ML'], 4.8, NULL),
(4, 'Mistral 7B', 'Language Model', 2023, '0.3', 'Open-weight 7B model outperforming Llama 2 13B. Sliding window attention for efficiency.', ARRAY['LLM','open-source','efficient','small'], 4.5, NULL),
(4, 'Mixtral 8x7B', 'Language Model', 2023, '0.1', 'Mixture-of-Experts model with 8 experts. Matches GPT-3.5 quality at fraction of the compute cost.', ARRAY['LLM','MoE','open-source','efficient'], 4.6, NULL),
(5, 'AlphaFold 2', 'Bioinformatics', 2021, '2.3', 'Protein structure prediction from amino acid sequence. Solved a 50-year grand challenge in biology.', ARRAY['biology','protein','science','breakthrough'], 5.0, NULL),
(5, 'Gemini Ultra', 'Language Model', 2024, '1.5', 'Multimodal AI with 1M token context window. Native understanding of text, code, images, and video.', ARRAY['LLM','multimodal','long-context','Google'], 4.6, NULL),
(6, 'Transformers', 'ML Framework', 2019, '4.40', 'State-of-the-art ML for PyTorch and TensorFlow. 200k+ downloads daily. Hub for pretrained models.', ARRAY['ML','NLP','framework','open-source'], 4.9, NULL),
(7, 'v0', 'AI Dev Tool', 2023, '3', 'Generative UI from natural language prompts. Produces React/shadcn components instantly.', ARRAY['AI','UI','codegen','React'], 4.4, 2.0),
(8, 'Terraform', 'IaC', 2014, '1.8', 'Infrastructure as code tool. Write declarative configs to provision cloud resources across providers.', ARRAY['IaC','DevOps','cloud','infrastructure'], 4.7, NULL),
(9, 'Cloudflare Workers', 'Serverless', 2017, NULL, 'Run JavaScript/WASM at the network edge in 300+ cities. Sub-millisecond cold starts.', ARRAY['serverless','edge','JavaScript','CDN'], 4.6, NULL),
(10, 'Delta Lake', 'Data Format', 2019, '3.1', 'Open-source storage layer with ACID transactions for data lakes. Foundation of Lakehouse architecture.', ARRAY['data','lakehouse','ACID','big-data'], 4.5, NULL),
(11, 'Stripe Radar', 'Fraud Detection', 2016, NULL, 'ML-powered fraud detection processing hundreds of signals per transaction in real time.', ARRAY['payments','ML','fraud','fintech'], 4.7, NULL),
(12, 'Linear', 'Project Management', 2020, '2024.4', 'Issue tracker with <50ms interactions. Git-integrated, keyboard-first workflow for engineering teams.', ARRAY['productivity','dev-tools','project-management','UX'], 4.8, 0.5),
(13, 'Temporal Cloud', 'Workflow Engine', 2022, NULL, 'Durable execution as a service. Guaranteed workflow completion even across failures and restarts.', ARRAY['distributed','reliability','workflow','microservices'], 4.6, NULL),
(14, 'Weaviate Vector DB', 'Vector Database', 2021, '1.25', 'Multi-modal vector search with GraphQL API. Built-in ML model integrations for semantic search.', ARRAY['vector-db','semantic-search','RAG','AI'], 4.5, NULL),
(17, 'Neon Serverless Postgres', 'Database', 2022, NULL, 'Postgres with 20ms cold start, database branching for dev/test, and autoscaling to zero.', ARRAY['postgres','serverless','database','branching'], 4.4, NULL),
(20, 'Stable Diffusion API', 'Image Generation', 2022, 'SDXL', 'Run Stable Diffusion and custom fine-tunes via REST API with autoscaling GPU infrastructure.', ARRAY['image-gen','AI','diffusion','API'], 4.3, NULL);

-- Innovations
INSERT INTO innovations (title, authors, institution, year, field, abstract, citations, arxiv_id, impact_score) VALUES
('Attention Is All You Need', ARRAY['Vaswani, A.', 'Shazeer, N.', 'Parmar, N.', 'Uszkoreit, J.'], 'Google Brain', 2017, 'Deep Learning', 'Introduces the Transformer architecture, replacing RNNs with self-attention mechanisms. Foundation of all modern LLMs.', 98000, '1706.03762', 99.9),
('BERT: Pre-training of Deep Bidirectional Transformers', ARRAY['Devlin, J.', 'Chang, M.W.', 'Lee, K.'], 'Google AI', 2018, 'NLP', 'Bidirectional encoder representations from transformers. Revolutionized NLP transfer learning benchmarks.', 45000, '1810.04805', 95.2),
('Constitutional AI: Harmlessness from AI Feedback', ARRAY['Bai, Y.', 'Jones, A.', 'Ndousse, K.'], 'Anthropic', 2022, 'AI Safety', 'Training AI to be helpful, harmless, and honest using a set of principles rather than human labeling for each behavior.', 1200, '2212.08073', 87.4),
('Scaling Laws for Neural Language Models', ARRAY['Kaplan, J.', 'McCandlish, S.', 'Henighan, T.'], 'OpenAI', 2020, 'Deep Learning', 'Empirical study showing predictable power-law relationships between model performance, compute, and data size.', 3500, '2001.08361', 92.1),
('LoRA: Low-Rank Adaptation of Large Language Models', ARRAY['Hu, E.J.', 'Shen, Y.', 'Wallis, P.'], 'Microsoft', 2021, 'NLP', 'Fine-tuning LLMs by training only low-rank decomposition matrices. Reduces trainable parameters by 10,000x.', 8900, '2106.09685', 93.5),
('Highly Accurate Protein Structure Prediction with AlphaFold', ARRAY['Jumper, J.', 'Evans, R.', 'Pritzel, A.'], 'DeepMind', 2021, 'Bioinformatics', 'End-to-end differentiable model achieving atomic-level protein structure accuracy, solving a 50-year challenge.', 22000, NULL, 98.7),
('Retrieval-Augmented Generation for Knowledge-Intensive NLP', ARRAY['Lewis, P.', 'Perez, E.', 'Piktus, A.'], 'Facebook AI', 2020, 'NLP', 'Combines parametric memory of LLMs with non-parametric retrieval from external documents to reduce hallucination.', 5600, '2005.11401', 91.8),
('Flash Attention: Fast and Memory-Efficient Exact Attention', ARRAY['Dao, T.', 'Fu, D.Y.', 'Ermon, S.'], 'Stanford', 2022, 'Systems', 'IO-aware exact attention algorithm 2-4x faster than standard attention, enabling longer context windows.', 4100, '2205.14135', 89.3),
('Mixtral of Experts', ARRAY['Jiang, A.Q.', 'Sablayrolles, A.', 'Roux, A.'], 'Mistral AI', 2024, 'Deep Learning', 'Sparse Mixture of Experts model using only 2 of 8 experts per token, matching dense 70B quality at 13B inference cost.', 890, '2401.04088', 84.6),
('RLHF: Learning to Summarize from Human Feedback', ARRAY['Stiennon, N.', 'Ouyang, L.', 'Wu, J.'], 'OpenAI', 2020, 'AI Alignment', 'Reinforcement learning from human feedback for summarization. Pioneered RLHF training methodology used in ChatGPT.', 3200, '2009.01325', 90.2),
('Mamba: Linear-Time Sequence Modeling', ARRAY['Gu, A.', 'Dao, T.'], 'Carnegie Mellon / Stanford', 2023, 'Deep Learning', 'Selective state space model achieving Transformer quality with linear-time inference. Promising Transformer alternative.', 1800, '2312.00752', 85.0),
('Kolmogorov-Arnold Networks', ARRAY['Liu, Z.', 'Wang, Y.', 'Vaidya, S.'], 'MIT / Caltech', 2024, 'Deep Learning', 'Alternative to MLPs using learnable activation functions on edges instead of fixed activations on nodes.', 650, '2404.19756', 78.3),
('GPT-4 Technical Report', ARRAY['OpenAI'], 'OpenAI', 2023, 'NLP', 'Multimodal large language model achieving human-level performance on academic and professional benchmarks.', 6700, '2303.08774', 94.1),
('Denoising Diffusion Probabilistic Models', ARRAY['Ho, J.', 'Jain, A.', 'Abbeel, P.'], 'UC Berkeley', 2020, 'Generative AI', 'Mathematical framework for diffusion models. Foundation of Stable Diffusion, DALL-E 2, and Midjourney.', 12000, '2006.11239', 96.4),
('World Models', ARRAY['Ha, D.', 'Schmidhuber, J.'], 'Google Brain / IDSIA', 2018, 'Reinforcement Learning', 'Agents learn compressed spatial and temporal representations of the world to plan and act inside dream environments.', 1100, '1803.10122', 82.7);

-- Trends
INSERT INTO trends (name, category, momentum_score, year_emerged, description, related_tags, adoption_stage) VALUES
('Large Language Models', 'AI/ML', 98, 2020, 'Foundation models trained on vast text corpora enabling few-shot learning across tasks without fine-tuning.', ARRAY['GPT','transformers','NLP','generative-AI'], 'mainstream'),
('Retrieval-Augmented Generation', 'AI/ML', 92, 2021, 'Grounding LLM outputs with real-time document retrieval to reduce hallucinations and enable up-to-date responses.', ARRAY['RAG','vector-db','semantic-search','LLM'], 'growing'),
('Edge Computing', 'Infrastructure', 85, 2019, 'Running compute at the network edge closer to users for lower latency, reduced bandwidth, and offline capability.', ARRAY['CDN','serverless','Cloudflare','latency'], 'mainstream'),
('Vector Databases', 'Databases', 88, 2021, 'Specialized databases for storing and querying high-dimensional embeddings for semantic similarity search.', ARRAY['embeddings','semantic-search','RAG','AI'], 'growing'),
('AI Agents', 'AI/ML', 95, 2023, 'Autonomous AI systems that plan, use tools, and execute multi-step tasks with minimal human intervention.', ARRAY['agents','autonomy','LLM','tools','planning'], 'emerging'),
('WebAssembly', 'Runtime', 72, 2018, 'Binary instruction format enabling near-native performance in browsers and server-side sandboxed environments.', ARRAY['WASM','performance','portable','sandboxing'], 'growing'),
('eBPF', 'Systems', 78, 2020, 'Extended Berkeley Packet Filter enabling safe, programmable kernel observability, networking, and security.', ARRAY['Linux','kernel','networking','observability'], 'growing'),
('Rust Language', 'Programming', 86, 2016, 'Systems programming language with memory safety guarantees without garbage collection. Replacing C/C++ in critical systems.', ARRAY['Rust','systems','memory-safety','performance'], 'growing'),
('Durable Execution', 'Architecture', 70, 2022, 'Programming model ensuring long-running workflows survive infrastructure failures through automatic checkpointing.', ARRAY['Temporal','reliability','distributed','workflow'], 'emerging'),
('Mixture of Experts', 'AI/ML', 83, 2022, 'Sparse model architecture routing tokens to specialized sub-networks for efficient scaling beyond dense transformer limits.', ARRAY['MoE','efficiency','scaling','LLM'], 'growing'),
('Serverless Databases', 'Databases', 80, 2022, 'Databases with automatic scaling, scale-to-zero billing, and connection pooling for cost-efficient cloud-native apps.', ARRAY['serverless','postgres','auto-scaling','cloud'], 'growing'),
('Multimodal AI', 'AI/ML', 90, 2022, 'AI models processing and generating across text, image, audio, and video modalities in unified architectures.', ARRAY['vision','audio','multimodal','GPT-4o','Gemini'], 'growing'),
('AI Code Generation', 'Developer Tools', 94, 2022, 'LLMs generating, explaining, and debugging code with increasing accuracy. Reshaping software development workflows.', ARRAY['Copilot','codegen','AI','developer-tools'], 'mainstream'),
('Homomorphic Encryption', 'Security', 55, 2021, 'Computing on encrypted data without decryption. Enables privacy-preserving AI inference and cloud computation.', ARRAY['encryption','privacy','ZKP','security'], 'emerging'),
('Neuromorphic Computing', 'Hardware', 48, 2020, 'Computing architectures mimicking biological neural networks for ultra-low-power AI inference at the edge.', ARRAY['hardware','brain-inspired','energy-efficient','AI'], 'emerging'),
('Federated Learning', 'AI/ML', 67, 2019, 'Training ML models across decentralized devices without sharing raw data, preserving privacy at scale.', ARRAY['privacy','distributed','ML','on-device'], 'growing'),
('Quantum Machine Learning', 'Computing', 45, 2021, 'Applying quantum algorithms to speed up ML training and inference on quantum hardware.', ARRAY['quantum','ML','hybrid','computing'], 'emerging'),
('Confidential Computing', 'Security', 63, 2020, 'Hardware-based trusted execution environments protecting data in use, even from cloud providers.', ARRAY['TEE','Intel-SGX','security','privacy'], 'growing'),
('Low-Code / No-Code AI', 'Developer Tools', 77, 2022, 'Visual tools enabling non-developers to build AI-powered applications without writing code.', ARRAY['low-code','AI','accessibility','automation'], 'growing'),
('On-Device AI', 'AI/ML', 82, 2023, 'Running neural networks directly on mobile and edge devices for privacy, speed, and offline capability.', ARRAY['mobile','inference','privacy','Apple','Qualcomm'], 'growing');
