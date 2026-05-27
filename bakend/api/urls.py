from django.urls import path
from . import views

urlpatterns = [
    path('pausas/', views.PausaActivaListCreateView.as_view(), name='pausas-list'),
    path('pausas/<int:pk>/', views.PausaActivaDeleteView.as_view(), name='pausas-delete'),
    path('estadisticas/', views.EstadisticasView.as_view(), name='estadisticas'),
]