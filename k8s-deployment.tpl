apiVersion: apps/v1
kind: Deployment
metadata:
  name: {APP_NAME}-deployment
  labels:
    app: {APP_NAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {APP_NAME}
  template:
    metadata:
      labels:
        app: {APP_NAME}
    spec:
      containers:
      - name: {APP_NAME}
        image: {IMAGE_URL}:{IMAGE_TAG}
        ports:
        - containerPort: 40080
        env:
          - name: SPRING_PROFILES_ACTIVE
            value: {SPRING_PROFILE}
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-jar
  namespace: demo
  annotations: 
    kubernets.io/ingress.class: "nginx"
spec:
  rules:
  - host: demojob.local.host
    http:
      paths:
      - path: 
        backend:
          serviceName: jar
          servicePort: 40080
