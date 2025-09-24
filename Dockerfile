# Build Stage
FROM python:3.12-slim AS builder

# Install uv package manager
RUN pip install uv

# Set working directory
WORKDIR /app

# Copy pyproject.toml for dependency installation
COPY pyproject.toml .

# Create virtual environment and install dependencies using uv
RUN uv venv /opt/venv
RUN /opt/venv/bin/pip install -e .

# Final Stage
FROM python:3.12-slim

# Copy the virtual environment from build stage
COPY --from=builder /opt/venv /opt/venv

# Make sure we use venv
ENV PATH="/opt/venv/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy application source code
COPY cc_simple_server/ ./cc_simple_server/
COPY pyproject.toml .

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser
RUN chown -R appuser:appuser /app
USER appuser

# Expose port 8000
EXPOSE 8000

# Set CMD to run FastAPI server on 0.0.0.0:8000
CMD ["uvicorn", "cc_simple_server.server:app", "--host", "0.0.0.0", "--port", "8000"]