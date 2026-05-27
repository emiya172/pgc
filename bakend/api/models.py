from django.db import models
from django.conf import settings

class PausaActiva(models.Model):
    CATEGORIAS = [
        ('Relajación', 'Relajación'),
        ('Estiramientos', 'Estiramientos'),
        ('Ojos', 'Ojos'),
        ('Movimiento', 'Movimiento'),
        ('Fuerza', 'Fuerza'),
    ]

    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    ejercicio = models.CharField(max_length=200)
    categoria = models.CharField(max_length=20, choices=CATEGORIAS)
    duracion = models.IntegerField()
    fecha = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-fecha']

    def __str__(self):
        return f"{self.usuario.name} - {self.ejercicio}"