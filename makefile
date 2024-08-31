# Define variables
FRONTEND_DIR = frontend
BACKEND_DIR = backend
BUILD_DIR = build
FRONTEND_BUILD_DIR = $(BUILD_DIR)/frontend
BACKEND_BUILD_DIR = $(BUILD_DIR)/backend
BACKEND_BIN = user_interface
# Default target to build everything
all: build-frontend build-backend copy-build

# Target to build the frontend project
build-frontend:
	@echo "Building frontend project..."
	@cd $(FRONTEND_DIR) && flutter build web

# Target to build the backend project
build-backend:
	@echo "Building backend project..."
	@cd $(BACKEND_DIR) && flutter build windows

# Target to copy the build results to the build directory
copy-build:
	@echo "Copying build results..."
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(BUILD_DIR)/assets
	@cp -r $(FRONTEND_DIR)/build/web $(BUILD_DIR)/assets
	@cp -r $(BACKEND_DIR)/build/windows/x64/runner/Release/* $(BUILD_DIR)/
    
# Clean up build directories
clean:
	@echo "Cleaning build directories..."
	@rm -rf $(BUILD_DIR)

# Phony targets
.PHONY: all build-frontend build-backend copy-build clean
