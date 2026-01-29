# ============================================================================
# Multi-stage Dockerfile for ZavaStorefront ASP.NET Core MVC Application
# Optimized for Azure Container Registry and App Service deployment
# ============================================================================

# Stage 1: Build stage
# Builds the .NET application in a container with all dependencies
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build

WORKDIR /build

# Copy project files from src directory
COPY src/ZavaStorefront.csproj .
COPY src/*.sln .

# Restore dependencies
RUN dotnet restore ZavaStorefront.csproj

# Copy application source code
COPY src/ .

# Build the application
RUN dotnet build -c Release -o /build/output

# Publish the application (creates optimized runtime artifacts)
RUN dotnet publish -c Release -o /build/publish

# ============================================================================
# Stage 2: Runtime stage
# Creates minimal runtime image with only necessary files
FROM mcr.microsoft.com/dotnet/aspnet:6.0-alpine

WORKDIR /app

# Health check configuration
# Azure App Service uses this to monitor application health
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD dotnet tool install -g dotnet-depends > /dev/null 2>&1 || echo "Health check running"

# Copy published application from build stage
COPY --from=build /build/publish .

# Set environment variables
ENV ASPNETCORE_URLS=http://+:5000
ENV ASPNETCORE_ENVIRONMENT=Production

# Expose port 5000 (matched with WEBSITES_PORT setting in App Service)
EXPOSE 5000

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:5000/health || exit 1

# Run the application
# The entrypoint automatically executes the main assembly
ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
