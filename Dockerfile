# =========================
# Build Stage
# =========================
FROM python:3.12 AS builder

# Install uv (single static binaries)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Copy metadata EARLY for caching
COPY pyproject.toml ./
# If your pyproject declares [project].readme = "README.md", you MUST copy it too
COPY README.md ./

# Create runtime venv and install deps
RUN python -m venv /opt/venv

# Install dependencies directly from pyproject.toml
RUN uv pip install --python /opt/venv/bin/python fastapi uvicorn pydantic httpx pytest pytest-cov

# Bring in app source
COPY cc_simple_server/ ./cc_simple_server/
# Copy tests so they exist in the runtime image
COPY tests/ ./tests/

# =========================
# Final Stage (runtime)
# =========================
FROM python:3.12-slim

# Use the venv from the build stage
ENV VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:${PATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Copy the virtual environment
COPY --from=builder /opt/venv /opt/venv

# Copy runtime application code
COPY cc_simple_server/ ./cc_simple_server/
# Copy tests for pytest execution
COPY --from=builder /app/tests/ ./tests/

# Non-root user for security
RUN addgroup --system app && adduser --system --ingroup app app \
 && chown -R app:app /app
USER app

# SQLite is in stdlib; no extra system packages needed
EXPOSE 8000

# Run FastAPI
CMD ["uvicorn", "cc_simple_server.server:app", "--host", "0.0.0.0", "--port", "8000"]