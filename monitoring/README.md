# Monitoring Layer - Prometheus & Grafana

This folder contains complete observability stack for Kubernetes cluster and microservices monitoring.

## 📋 What's Included

### 1. Prometheus
- Metrics collection and storage
- Scrapes metrics every 15 seconds
- Retention: 15 days
- Storage: 50GB (for typical workloads)

### 2. Grafana
- Data visualization dashboards
- Pre-built dashboard for Kubernetes
- Default credentials: admin/admin
- Port: 3000

### 3. ServiceMonitor
- Automatic scrape target discovery
- Monitor pods with Prometheus annotations
- Self-healing configuration

## 📊 Monitoring Architecture

\`\`\`
┌──────────────────────────────────────┐
│     Microservices Pods               │
│  (with metrics on /metrics port)     │
├──────────────────────────────────────┤
│              ↓                       │
│   Prometheus Scraper (every 15s)     │
│              ↓                       │
│  Time-Series Database (TSDB)         │
│  ├─ Pod metrics                      │
│  ├─ Node metrics                     │
│  ├─ API latency                      │
│  └─ Custom application metrics       │
│              ↓                       │
│   Grafana Visualization              │
│  ├─ Cluster Dashboard                │
│  ├─ Pod Resource Usage               │
│  ├─ API Performance                  │
│  └─ Custom Dashboards                │
│              ↓                       │
│        Analytics & Alerts            │
└──────────────────────────────────────┘
\`\`\`

## 🚀 What Gets Monitored

### Cluster Metrics
- Node CPU, Memory, Disk usage
- Pod resource utilization
- Network I/O
- Volume usage

### Application Metrics
- API request count
- Request latency (p50, p95, p99)
- Error rates
- Custom application metrics

### Database Metrics
- Connection count
- Query latency
- Transaction rates
- Cache hit ratio

## 📈 Key Metrics

| Metric | Source | Alert Threshold |
|--------|--------|-----------------|
| Pod CPU | kubelet | > 80% |
| Pod Memory | kubelet | > 85% |
| Node CPU | kubelet | > 75% |
| Request Latency | Application | > 500ms |
| Error Rate | Application | > 5% |
| Disk Usage | kubelet | > 90% |

## 🧪 Accessing Monitoring

### Prometheus UI
\`\`\`bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Access: http://localhost:9090
# Query metrics: up, container_cpu_usage_seconds_total, etc.
\`\`\`

### Grafana UI
\`\`\`bash
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Access: http://localhost:3000
# Login: admin / admin
\`\`\`

## 📊 Sample Queries

### Prometheus PromQL Queries

**Pod CPU Usage:**
\`\`\`promql
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)
\`\`\`

**Pod Memory Usage:**
\`\`\`promql
sum(container_memory_usage_bytes) by (pod)
\`\`\`

**API Request Rate:**
\`\`\`promql
rate(http_requests_total[5m])
\`\`\`

**Error Rate:**
\`\`\`promql
rate(http_requests_total{status=~"5.."}[5m])
\`\`\`

## 🎯 Grafana Dashboards

Pre-configured dashboards:
1. **Kubernetes Cluster** - Overall cluster health
2. **Pod Resource Usage** - Per-pod CPU/memory
3. **API Performance** - Request latency & errors
4. **Database** - Query performance

## 💾 Data Retention

| Component | Retention | Purpose |
|-----------|-----------|---------|
| Prometheus | 15 days | Long-term metrics |
| Grafana | N/A | UI & dashboards |
| Alerts | 24 hours | Recent incidents |

## 🔔 Alerting Setup

Basic alerts configured:
- High CPU usage (> 80%)
- High memory usage (> 85%)
- Pod crashes (restarts > 5)
- Disk full (> 90%)

## 📝 Typical Monitoring Workflow

1. **Application generates metrics** (/metrics endpoint)
2. **Prometheus scrapes** every 15 seconds
3. **Metrics stored** in time-series database
4. **Grafana queries** metrics for visualization
5. **Dashboards show** real-time status
6. **Alerts trigger** on threshold violations

## 💰 Cost Estimation

| Component | Monthly Cost |
|-----------|--------------|
| Prometheus Pod | \$0.50 |
| Grafana Pod | \$0.30 |
| Storage (50GB) | \$5.00 |
| **Total** | **~\$6/month** |

## 🧹 Cleanup

Remove monitoring stack:
\`\`\`bash
kubectl delete namespace monitoring
\`\`\`

---

For deployment results, see \`MONITORING-RESULTS.md\`
