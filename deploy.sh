sudo docker-compose -f docker-compose-prod.yaml up -d &&
sleep 5 &&
sudo docker exec dockerexample_django_1 python3 manage.py migrate
