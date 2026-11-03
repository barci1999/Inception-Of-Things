#!/bin/bash

# (Nacho) Crea en el GitLab local el proyecto público root/nmagro-r-iot-argocd y le sube la app
# de confs/app/ en la carpeta k8s/. Argo CD lo lee desde dentro del clúster sin contraseña:
#   http://gitlab.gitlab.svc.cluster.local/root/nmagro-r-iot-argocd.git
# Se usa gitlab-rails dentro del pod, así no hace falta ningún token ni contraseña.
NAMESPACE="gitlab"
PROJECT="nmagro-r-iot-argocd"
APP_DIR="confs/app"

POD=$(sg docker -c "kubectl -n $NAMESPACE get pods -l app=gitlab -o jsonpath='{.items[0].metadata.name}'" 2>/dev/null)
if [ -z "$POD" ]; then
    echo "❌ Error: GitLab is not running. Run gitlab.sh first."
    exit 1
fi

echo "📦 Copying the app ($APP_DIR) into the GitLab pod..."
sg docker -c "kubectl -n $NAMESPACE exec $POD -- rm -rf /tmp/iot-app"
if ! sg docker -c "kubectl -n $NAMESPACE cp $APP_DIR $POD:/tmp/iot-app"; then
    echo "❌ Error: could not copy $APP_DIR into the GitLab pod."
    exit 1
fi

echo "🦊 Creating project 'root/$PROJECT' and uploading k8s/ (takes about a minute)..."
if ! sg docker -c "kubectl -n $NAMESPACE exec -i $POD -- sh -c 'cat > /tmp/iot-repo.rb && gitlab-rails runner /tmp/iot-repo.rb'" <<EOF
user = User.find_by_username('root')
project = Project.find_by_full_path('root/$PROJECT')
if project.nil?
  project = ::Projects::CreateService.new(user, name: '$PROJECT', path: '$PROJECT',
    visibility_level: Gitlab::VisibilityLevel::PUBLIC).execute
  abort("Project not created: #{project.errors.full_messages.join(', ')}") unless project.persisted?
  puts "Project created: #{project.full_path} (public)"
else
  puts "Project already exists: #{project.full_path}"
end
Dir.glob('/tmp/iot-app/*.yaml').sort.each do |f|
  path = "k8s/#{File.basename(f)}"
  content = File.read(f)
  blob = project.repository.exists? ? project.repository.blob_at('main', path) : nil
  if blob.nil?
    project.repository.create_file(user, path, content, message: "add #{path}", branch_name: 'main')
    puts "  created #{path}"
  elsif blob.data != content
    project.repository.update_file(user, path, content, message: "update #{path}", branch_name: 'main')
    puts "  updated #{path}"
  else
    puts "  #{path} already up to date"
  end
end
EOF
then
    echo "❌ Error: could not create the project in GitLab."
    exit 1
fi

echo "✅ Repo ready: http://localhost/root/$PROJECT"
