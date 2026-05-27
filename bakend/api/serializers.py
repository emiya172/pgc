from rest_framework import serializers
from .models import PausaActiva

class PausaActivaSerializer(serializers.ModelSerializer):
    class Meta:
        model = PausaActiva
        fields = ['id', 'ejercicio', 'categoria', 'duracion', 'fecha'] 
