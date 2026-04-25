# Padrões Avançados de Multi-Agentes

## Padrão Reflexão — Agente que Revisa o Próprio Output

```python
async def agente_reflexivo(tarefa: str, max_ciclos: int = 3) -> str:
    rascunho = await gerar_rascunho(tarefa)

    for ciclo in range(max_ciclos):
        critica = await client.messages.create(
            model='claude-sonnet-4-5',
            system="""Você é um revisor crítico. Analise o texto e liste:
            1. Erros factuais ou lógicos
            2. Lacunas importantes
            3. Melhorias específicas sugeridas
            Se o texto estiver adequado, responda: APROVADO""",
            messages=[{'role': 'user', 'content': f"Tarefa original: {tarefa}\n\nTexto: {rascunho}"}]
        )

        if 'APROVADO' in critica.content[0].text:
            break

        # Incorporar críticas
        rascunho = await incorporar_criticas(rascunho, critica.content[0].text)

    return rascunho
```

## Padrão Debate — Dois Agentes com Posições Opostas

```python
async def debate_agentes(questao: str, rodadas: int = 3) -> str:
    historico = []

    for rodada in range(rodadas):
        # Agente Pró
        pro = await client.messages.create(
            system="Você defende a posição PRO. Use evidências e lógica.",
            messages=[{'role': 'user', 'content': f"Questão: {questao}\n\nHistórico: {historico}"}]
        )

        # Agente Contra (vê o argumento do Pró)
        contra = await client.messages.create(
            system="Você defende a posição CONTRA. Refute os argumentos apresentados.",
            messages=[{'role': 'user', 'content': f"Questão: {questao}\nArgumento PRO: {pro.content[0].text}"}]
        )

        historico.append({'rodada': rodada+1, 'pro': pro.content[0].text, 'contra': contra.content[0].text})

    # Árbitro sintetiza
    arbitro = await client.messages.create(
        system="Você é um árbitro imparcial. Sintetize os melhores pontos de ambos os lados.",
        messages=[{'role': 'user', 'content': str(historico)}]
    )

    return arbitro.content[0].text
```

## Padrão Especialistas em Paralelo + Síntese

```python
ESPECIALISTAS = {
    'tecnico':  'Você é um engenheiro sênior. Analise viabilidade técnica.',
    'negocio':  'Você é um analista de negócio. Analise ROI e impacto.',
    'usuario':  'Você é um especialista em UX. Analise impacto nos usuários.',
    'seguranca':'Você é um especialista em segurança. Analise riscos.',
}

async def analise_multiperspectiva(problema: str) -> dict:
    # Paralelo
    analises = await asyncio.gather(*[
        client.messages.create(
            model='claude-sonnet-4-5',
            system=prompt,
            messages=[{'role': 'user', 'content': problema}]
        )
        for prompt in ESPECIALISTAS.values()
    ])

    resultado = {
        nome: resp.content[0].text
        for nome, resp in zip(ESPECIALISTAS.keys(), analises)
    }

    # Síntese
    sintese = await client.messages.create(
        model='claude-opus-4-5',
        system='Sintetize as análises em uma recomendação única e equilibrada.',
        messages=[{'role': 'user', 'content': str(resultado)}]
    )

    resultado['sintese'] = sintese.content[0].text
    return resultado
```


---

← [[README|Multi Agentes]]
