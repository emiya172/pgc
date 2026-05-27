from rest_framework import generics, permissions
from rest_framework.response import Response
from django.db.models import Count
from django.utils import timezone
from datetime import timedelta
from .models import PausaActiva
from .serializers import PausaActivaSerializer

class PausaActivaListCreateView(generics.ListCreateAPIView):
    serializer_class = PausaActivaSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return PausaActiva.objects.filter(usuario=self.request.user)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user)

class PausaActivaDeleteView(generics.DestroyAPIView):
    serializer_class = PausaActivaSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return PausaActiva.objects.filter(usuario=self.request.user)

class EstadisticasView(generics.GenericAPIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        usuario = request.user
        ahora = timezone.now()
        hoy = ahora.date()
        inicio_semana = ahora - timedelta(days=ahora.weekday())
        inicio_mes = ahora.replace(day=1)

        estadisticas = {
            'total': PausaActiva.objects.filter(usuario=usuario).count(),
            'hoy': PausaActiva.objects.filter(usuario=usuario, fecha__date=hoy).count(),
            'semana': PausaActiva.objects.filter(usuario=usuario, fecha__gte=inicio_semana).count(),
            'mes': PausaActiva.objects.filter(usuario=usuario, fecha__gte=inicio_mes).count(),
            'por_categoria': list(PausaActiva.objects.filter(usuario=usuario)
                .values('categoria').annotate(total=Count('categoria')))
        }
        return Response(estadisticas)