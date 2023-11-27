#!/bin/bash

# Function to exit the script
exit_script() {
    echo "Thank you for using the script, $user_name. Goodbye!"
    exit 0
}

# Function to check if a directory exists
check_directory() {
    if [ -d "$1" ]; then
        return 0
    else
        return 1
    fi
}

# Function to list Docker images
list_docker_images() {
    echo "Listing all Docker images..."
    docker images | awk 'NR>1 {print NR-1 ": " $1 ":" $2}'
}

# Function to create a Docker image
create_docker_image() {
    echo "Please enter the path to your project directory:"
    read project_path
    if ! check_directory "$project_path"; then
        echo "Directory does not exist. Please try again."
        return 1
    fi

    echo "Please enter a name for your Docker image (use lowercase letters only):"
    read image_name
    if [[ ! $image_name =~ ^[a-z0-9]+([-_.][a-z0-9]+)*$ ]]; then
        echo "Invalid image name. Image names must be lowercase and can include digits, dashes, and underscores."
        return 1
    fi

    echo "Please enter a tag for your Docker image (e.g., 'v1.0', 'latest'):"
    read image_tag

    echo "Creating Docker image $image_name:$image_tag..."
    docker build -t "$image_name:$image_tag" "$project_path"
    if [ $? -eq 0 ]; then
        echo "Docker image created successfully."
    else
        echo "Failed to create Docker image."
        return 1
    fi
    return 0
}

# Function to choose the next action
choose_next_action() {
    echo "What would you like to do next, $user_name?"
    echo "1. Create a Docker image"
    echo "2. Run a Docker image"
    echo "3. Push a Docker image to Docker Hub"
    echo "4. Exit"
    read next_action

    case $next_action in
        1) 
            if ! create_docker_image; then
                echo "Would you like to try again or go back? (Try/Back)"
                read decision
                [[ "$decision" == "Back" ]] && continue
            fi
            ;;
        2) 
            if ! run_docker_image; then
                echo "Would you like to try again or go back? (Try/Back)"
                read decision
                [[ "$decision" == "Back" ]] && continue
            fi
            ;;
        3) 
            if ! push_docker_image; then
                echo "Would you like to try again or go back? (Try/Back)"
                read decision
                [[ "$decision" == "Back" ]] && continue
            fi
            ;;
        4) 
            exit_script
            ;;
        *) 
            echo "Invalid choice. Please try again."
            ;;
    esac
}


# Function to run a Docker image
run_docker_image() {
    list_docker_images
    echo "Please enter the number of the Docker image you want to run:"
    read image_number
    selected_image=$(docker images | awk 'NR=='$((image_number + 1))' {print $1 ":" $2}')

    echo "Please enter the ports to use (e.g., 8080:80):"
    read ports
    docker run -d -p "$ports" "$selected_image"
    if [ $? -eq 0 ]; then
        echo "Docker image is running."
    else
        echo "Failed to run Docker image."
        return 1
    fi
    return 0
}

# Function to push a Docker image to Docker Hub 

push_docker_image() {
    list_docker_images

    echo "Please enter the number of the Docker image you want to push:"
    read image_number
    selected_image=$(docker images | awk 'NR=='$((image_number + 1))' {print $1 ":" $2}')

    echo "Please enter the tag for the Docker image you want to push (e.g., 'v1.0', 'latest') or type 'Exit' to quit:"
    read image_tag
    [[ "$image_tag" == "Exit" ]] && exit_script

    echo "Please enter the Docker Hub repository (e.g., username/repository) or type 'Exit' to quit:"
    read docker_hub_repo
    [[ "$docker_hub_repo" == "Exit" ]] && exit_script

    echo "Have you already logged in to Docker Hub? (Yes/No)"
    read login_status

    if [[ "$login_status" == "No" || "$login_status" == "n" ]]; then
        docker login
        if [ $? -ne 0 ]; then
            echo "Docker login failed. Would you like to try again or go back? (Try/Back)"
            read decision
            [[ "$decision" == "Back" ]] && return
            docker login
        fi
    fi

    new_image_name="$docker_hub_repo:$image_tag"
    docker tag "$selected_image" "$new_image_name"
    docker push "$new_image_name"

    if [ $? -eq 0 ]; then
        echo "Docker image $new_image_name has been pushed to Docker Hub."
    else
        echo "Failed to push Docker image to Docker Hub."
    fi
}


# Main script starts here
echo "Welcome to the Docker Management Script!"
echo "Please enter your name:"
read user_name

while true; do
    echo "Hello, $user_name! What would you like to do?"
    echo "1. Create a Docker image"
    echo "2. Run a Docker image"
    echo "3. Push a Docker image to Docker Hub"
    echo "4. Exit"
    read choice

    case $choice in
        1) 
            if ! create_docker_image; then
                echo "Would you like to try again or go back? (Try/Back)"
                read decision
                [[ "$decision" == "Back" ]] && continue
            fi
            ;;
        2) 
            if ! run_docker_image; then
                echo "Would you like to try again or go back? (Try/Back)"
                read decision
                [[ "$decision" == "Back" ]] && continue
            fi
            ;;
        3) 
            if ! push_docker_image; then
                echo "Would you like to try again or go back? (Try/Back)"
                read decision
                [[ "$decision" == "Back" ]] && continue
            fi
            ;;
        4) 
            exit_script
            ;;
        *) 
            echo "Invalid choice. Please try again."
            ;;
    esac
done
