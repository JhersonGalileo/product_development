#Tarea FAST API, CALCULADORA

@app.get('/suma/{array}')
#def suma(array: List[str]):
def suma(array):
    result = eval(array)
    total = 0
    for item in result:
        total+= int(item)
    #print(total)
    return {'Total': total}

@app.get('/resta/{array}')
#def suma(array: List[str]):
def suma(array):
    result = eval(array)
    total = 0
    for item in result:
        if total==0:
            total=item
        else:
            total-= int(item)
    #print(total)
    return {'Total': total}


@app.get('/multi/{array}')
#def suma(array: List[str]):
def suma(array):
    result = eval(array)
    total = 1
    for item in result:
        total*= int(item)
    #print(total)
    return {'Total': total}

@app.get('/divi/{array}')
#def suma(array: List[str]):
def suma(array):
    result = eval(array)
    total = 1
    try:
        for item in result:
            total/= int(item)
        #print(total)
    except Exception as error:
        return{'Error':'Valores incorrectos para dividir'}
    return {'Total': total}


@app.get('/calc/{array}')
def calculadora(array, operation:str):
    result = eval(array)
    total = 0
    if operation=='suma':
        for item in result:
            total+= int(item)
        
    elif  operation=='resta':
        for item in result:
            if total==0:
                total=item
            else:
                total-= int(item)
    elif  operation=='multi':
        total = 1
        for item in result:
            total*= int(item)
    else:
        total = 1
        try:
            for item in result:
                total/= int(item)  
        except Exception as error:
            return{'Error':'Valores incorrectos para dividir'}
            
    return {'Total': total}